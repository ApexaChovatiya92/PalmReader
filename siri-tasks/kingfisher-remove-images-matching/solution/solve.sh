#!/bin/bash
# Reference solution: add ImageCache.removeImages(forKeysMatching:...).
# Memory keys are mapped back to their original key in a dictionary; on disk the original
# key is kept in an extended attribute on each cache file, since file names are hashed.
set -euo pipefail
cd "$WORKSPACE"
patch -p1 --forward --no-backup-if-mismatch <<'KF_PATCH'
diff --git a/Sources/Cache/ImageCache.swift b/Sources/Cache/ImageCache.swift
index 019d9c00..d3c347ce 100644
--- a/Sources/Cache/ImageCache.swift
+++ b/Sources/Cache/ImageCache.swift
@@ -178,6 +178,17 @@ open class ImageCache: @unchecked Sendable {
     public let diskStorage: DiskStorage.Backend<Data>
     
     private let ioQueue: DispatchQueue
+
+    // Maps each computed memory cache key to the original key it was stored under, so that matching removals can
+    // test the original key without parsing the processor identifier back out of the computed key.
+    private let memoryKeyOriginsLock = NSLock()
+    private var memoryKeyOrigins: [String: String] = [:]
+
+    private func withMemoryKeyOrigins<R>(_ body: (inout [String: String]) -> R) -> R {
+        memoryKeyOriginsLock.lock()
+        defer { memoryKeyOriginsLock.unlock() }
+        return body(&memoryKeyOrigins)
+    }
     
     /// A closure that specifies the disk cache path based on a given path and the cache name.
     public typealias DiskCachePathClosure = @Sendable (URL, String) -> URL
@@ -350,6 +361,7 @@ open class ImageCache: @unchecked Sendable {
         let computedKey = key.computedKey(with: identifier)
         // Memory storage should not throw.
         memoryStorage.storeNoThrow(value: image, forKey: computedKey, expiration: options.memoryCacheExpiration)
+        withMemoryKeyOrigins { $0[computedKey] = key }
         
         guard toDisk else {
             if let completionHandler = completionHandler {
@@ -501,6 +513,9 @@ open class ImageCache: @unchecked Sendable {
                 writeOptions: writeOptions,
                 forcedExtension: forcedExtension
             )
+            // Hashed file names cannot be turned back into keys, so keep the original key with the file.
+            setOriginalCacheKey(
+                key, at: diskStorage.cacheFileURL(forKey: computedKey, forcedExtension: forcedExtension))
             result = CacheStoreResult(memoryCacheResult: .success(()), diskCacheResult: .success(()))
         } catch {
             let diskError: KingfisherError
@@ -557,6 +572,57 @@ open class ImageCache: @unchecked Sendable {
             completionHandler: { _ in completionHandler?() } // This is a version which ignores error.
         )
     }
+
+    /// Removes every image whose original cache key matches the given predicate.
+    ///
+    /// The `predicate` receives the key that was passed as `forKey` when the image was stored. A match removes the
+    /// images stored under that key for every processor identifier. Disk files that were not written through
+    /// ``ImageCache``, and so carry no original key, are left untouched.
+    ///
+    /// - Parameters:
+    ///   - predicate: Returns `true` for the original keys whose images should be removed.
+    ///   - fromMemory: Whether matching images should be removed from the memory storage. The default is `true`.
+    ///   - fromDisk: Whether matching images should be removed from the disk storage. The default is `true`.
+    ///   - callbackQueue: The callback queue on which the `completionHandler` is invoked. The default is
+    ///   ``CallbackQueue/untouch``.
+    ///   - completionHandler: A closure that is invoked when the removal operation finishes.
+    open func removeImages(
+        forKeysMatching predicate: @escaping @Sendable (String) -> Bool,
+        fromMemory: Bool = true,
+        fromDisk: Bool = true,
+        callbackQueue: CallbackQueue = .untouch,
+        completionHandler: (@Sendable () -> Void)? = nil
+    )
+    {
+        if fromMemory {
+            // Evaluate the predicate outside the lock, so it can safely call back into this cache.
+            let origins = withMemoryKeyOrigins { $0 }
+            let matched = origins.filter { predicate($0.value) }.map(\.key)
+            withMemoryKeyOrigins { origins in
+                matched.forEach { origins.removeValue(forKey: $0) }
+            }
+            matched.forEach { memoryStorage.remove(forKey: $0) }
+        }
+
+        @Sendable func callHandler() {
+            if let completionHandler = completionHandler {
+                callbackQueue.execute { completionHandler() }
+            }
+        }
+
+        guard fromDisk else {
+            callHandler()
+            return
+        }
+        ioQueue.async {
+            let urls = (try? self.diskStorage.allFileURLs(for: [.isDirectoryKey])) ?? []
+            for url in urls {
+                guard let key = originalCacheKey(at: url), predicate(key) else { continue }
+                try? self.diskStorage.removeFile(at: url)
+            }
+            callHandler()
+        }
+    }
     
     func removeImage(
         forKey key: String,
@@ -571,6 +637,7 @@ open class ImageCache: @unchecked Sendable {
 
         if fromMemory {
             memoryStorage.remove(forKey: computedKey)
+            withMemoryKeyOrigins { _ = $0.removeValue(forKey: computedKey) }
         }
         
         @Sendable func callHandler(_ error: (any Error)?) {
@@ -902,6 +969,7 @@ open class ImageCache: @unchecked Sendable {
     /// Clears the memory storage of this cache.
     @objc public func clearMemoryCache() {
         memoryStorage.removeAll()
+        withMemoryKeyOrigins { $0.removeAll() }
     }
     
     /// Clears the disk storage of this cache. 
@@ -1384,6 +1452,24 @@ open class ImageCache: @unchecked Sendable {
             )
         }
     }
+
+    /// Removes every image whose original cache key matches the given predicate.
+    ///
+    /// - Parameters:
+    ///   - predicate: Returns `true` for the original keys whose images should be removed.
+    ///   - fromMemory: Whether matching images should be removed from the memory storage. The default is `true`.
+    ///   - fromDisk: Whether matching images should be removed from the disk storage. The default is `true`.
+    open func removeImages(
+        forKeysMatching predicate: @escaping @Sendable (String) -> Bool,
+        fromMemory: Bool = true,
+        fromDisk: Bool = true
+    ) async {
+        await withCheckedContinuation { continuation in
+            removeImages(forKeysMatching: predicate, fromMemory: fromMemory, fromDisk: fromDisk) {
+                continuation.resume()
+            }
+        }
+    }
     
     /// Retrieves an image for a given key from the cache, either from memory storage or disk storage.
     ///
@@ -1523,3 +1609,25 @@ extension String {
         }
     }
 }
+
+// The extended attribute that keeps the original cache key on a disk cache file.
+private let originalCacheKeyAttribute = "com.onevcat.Kingfisher.originalKey"
+
+private func setOriginalCacheKey(_ key: String, at url: URL) {
+    let bytes = Array(key.utf8)
+    _ = url.withUnsafeFileSystemRepresentation { path -> Int32 in
+        guard let path else { return -1 }
+        return setxattr(path, originalCacheKeyAttribute, bytes, bytes.count, 0, 0)
+    }
+}
+
+private func originalCacheKey(at url: URL) -> String? {
+    url.withUnsafeFileSystemRepresentation { path -> String? in
+        guard let path else { return nil }
+        let size = getxattr(path, originalCacheKeyAttribute, nil, 0, 0, 0)
+        guard size >= 0 else { return nil }
+        var bytes = [UInt8](repeating: 0, count: size)
+        guard getxattr(path, originalCacheKeyAttribute, &bytes, size, 0, 0) == size else { return nil }
+        return String(decoding: bytes, as: UTF8.self)
+    }
+}
KF_PATCH
