siri_require_file "$WORKSPACE/Package.swift"
siri_require_file "$WORKSPACE/Sources/Cache/ImageCache.swift"
siri_require_tool swift "swift --version"

CHECK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/kf-remove-matching.XXXXXX")"
remove_check_dir() {
  rm -rf "$CHECK_DIR"
}
siri_on_cleanup remove_check_dir

# Test the changed library as a local package. The folder is named Kingfisher so that
# the package identity matches, whatever the workspace folder is called.
mkdir -p "$CHECK_DIR/Kingfisher" "$CHECK_DIR/Check/Tests/RemoveMatchingTests"
cp -R "$WORKSPACE/." "$CHECK_DIR/Kingfisher/" || siri_error check_block_crashed "Cannot copy the workspace."
rm -rf "$CHECK_DIR/Kingfisher/.build" "$CHECK_DIR/Kingfisher/.swiftpm"

cat > "$CHECK_DIR/Check/Package.swift" <<'EOF'
// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "RemoveMatchingCheck",
    platforms: [.macOS(.v13)],
    dependencies: [.package(path: "../Kingfisher")],
    targets: [
        .testTarget(
            name: "RemoveMatchingTests",
            dependencies: [.product(name: "Kingfisher", package: "Kingfisher")]
        )
    ],
    swiftLanguageModes: [.v5]
)
EOF

cat > "$CHECK_DIR/Check/Tests/RemoveMatchingTests/RemoveMatchingTests.swift" <<'EOF'
import XCTest
import AppKit
import Kingfisher

private final class KeyRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = Set<String>()
    func record(_ key: String) { lock.lock(); storage.insert(key); lock.unlock() }
    var keys: Set<String> { lock.lock(); defer { lock.unlock() }; return storage }
}

final class RemoveMatchingTests: XCTestCase {

    private var roots: [URL] = []

    override func tearDown() {
        roots.forEach { try? FileManager.default.removeItem(at: $0) }
        roots = []
        super.tearDown()
    }

    private func makeRoot() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("kf-remove-matching-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        roots.append(url)
        return url
    }

    private func makeCache(name: String, root: URL) throws -> ImageCache {
        try ImageCache(name: name, cacheDirectoryURL: root)
    }

    private func makeImage(_ seed: Int) -> (KFCrossPlatformImage, Data) {
        let size = 4 + seed % 5
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0)!
        for x in 0..<size {
            for y in 0..<size {
                let v = CGFloat((x * 31 + y * 17 + seed * 7) % 255) / 255
                rep.setColor(NSColor(deviceRed: v, green: 1 - v, blue: 0.5, alpha: 1), atX: x, y: y)
            }
        }
        let data = rep.representation(using: .png, properties: [:])!
        return (KFCrossPlatformImage(data: data)!, data)
    }

    private func store(
        _ cache: ImageCache, _ key: String, id: String = "", seed: Int = 0, toDisk: Bool = true
    ) async throws {
        let (image, data) = makeImage(seed)
        try await cache.store(image, original: data, forKey: key, processorIdentifier: id, toDisk: toDisk)
    }

    private func files(in cache: ImageCache) -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: cache.diskStorage.directoryURL.path)) ?? []
    }

    // Matching keys are removed from both layers, for every processor identifier; others stay.
    func testRemovesMatchingKeysFromMemoryAndDisk() async throws {
        let cache = try makeCache(name: "matching", root: makeRoot())
        try await store(cache, "avatar/1", seed: 1)
        try await store(cache, "avatar/1", id: "round", seed: 2)
        try await store(cache, "avatar/2", seed: 3)
        try await store(cache, "banner/1", seed: 4)
        try await store(cache, "user@host/avatar/9", seed: 5)

        await cache.removeImages(forKeysMatching: { $0.hasPrefix("avatar/") })

        XCTAssertEqual(cache.imageCachedType(forKey: "avatar/1", processorIdentifier: ""), .none)
        XCTAssertEqual(cache.imageCachedType(forKey: "avatar/1", processorIdentifier: "round"), .none)
        XCTAssertEqual(cache.imageCachedType(forKey: "avatar/2", processorIdentifier: ""), .none)
        XCTAssertFalse(cache.diskStorage.isCached(forKey: "avatar/1"))
        XCTAssertFalse(cache.diskStorage.isCached(forKey: "avatar/2"))

        XCTAssertEqual(cache.imageCachedType(forKey: "banner/1", processorIdentifier: ""), .memory)
        XCTAssertEqual(cache.imageCachedType(forKey: "user@host/avatar/9", processorIdentifier: ""), .memory)
        XCTAssertTrue(cache.diskStorage.isCached(forKey: "banner/1"))
        XCTAssertTrue(cache.diskStorage.isCached(forKey: "user@host/avatar/9"))
        XCTAssertEqual(files(in: cache).count, 2)
    }

    // The predicate sees exactly the original keys: no processor suffixes, no file names.
    func testPredicateReceivesOriginalKeys() async throws {
        let cache = try makeCache(name: "keys", root: makeRoot())
        try await store(cache, "a/1", seed: 1)
        try await store(cache, "a/1", id: "blur(2.0)", seed: 2)
        try await store(cache, "me@example.com/pic", seed: 3)
        try await store(cache, "memory-only", seed: 4, toDisk: false)

        let recorder = KeyRecorder()
        await cache.removeImages(forKeysMatching: { key in
            recorder.record(key)
            return false
        })

        XCTAssertEqual(recorder.keys, ["a/1", "me@example.com/pic", "memory-only"])
        XCTAssertEqual(cache.imageCachedType(forKey: "a/1", processorIdentifier: "blur(2.0)"), .memory)
        XCTAssertEqual(cache.imageCachedType(forKey: "memory-only", processorIdentifier: ""), .memory)
        XCTAssertEqual(files(in: cache).count, 3)
    }

    // A new cache object on the same folder can still remove files by their original keys.
    func testDiskKeysSurviveNewCacheInstance() async throws {
        let root = makeRoot()
        let first = try makeCache(name: "shared", root: root)
        try await store(first, "doc/1", seed: 1)
        try await store(first, "doc/2", id: "thumb", seed: 2)
        try await store(first, "keep/1", seed: 3)

        let second = try makeCache(name: "shared", root: root)
        XCTAssertEqual(second.diskStorage.directoryURL, first.diskStorage.directoryURL)
        await second.removeImages(forKeysMatching: { $0.hasPrefix("doc/") })

        XCTAssertEqual(second.imageCachedType(forKey: "doc/1", processorIdentifier: ""), .none)
        XCTAssertEqual(second.imageCachedType(forKey: "doc/2", processorIdentifier: "thumb"), .none)
        XCTAssertEqual(second.imageCachedType(forKey: "keep/1", processorIdentifier: ""), .disk)
        XCTAssertFalse(first.diskStorage.isCached(forKey: "doc/1"))
        XCTAssertEqual(files(in: second).count, 1)
    }

    func testFromMemoryAndFromDiskFlags() async throws {
        let cache = try makeCache(name: "flags", root: makeRoot())
        try await store(cache, "m/1", seed: 1)
        try await store(cache, "d/1", seed: 2)

        await cache.removeImages(forKeysMatching: { $0 == "m/1" }, fromMemory: true, fromDisk: false)
        XCTAssertFalse(cache.memoryStorage.isCached(forKey: "m/1"))
        XCTAssertTrue(cache.diskStorage.isCached(forKey: "m/1"))

        await cache.removeImages(forKeysMatching: { $0 == "d/1" }, fromMemory: false, fromDisk: true)
        XCTAssertTrue(cache.memoryStorage.isCached(forKey: "d/1"))
        XCTAssertFalse(cache.diskStorage.isCached(forKey: "d/1"))
    }

    // The cache folder holds only the image files, and normal cleaning does not break matching.
    func testNoExtraFilesAndCleaningKeepsKeys() async throws {
        let cache = try makeCache(name: "files", root: makeRoot())
        for i in 0..<4 {
            try await store(cache, "item/\(i)", seed: i)
        }
        // Store one key again, as a refreshed download would.
        try await store(cache, "item/0", seed: 9)

        let names = files(in: cache)
        XCTAssertEqual(names.count, 4)
        let fileBytes = try names.reduce(UInt(0)) { total, name in
            let path = cache.diskStorage.directoryURL.appendingPathComponent(name).path
            let size = try FileManager.default.attributesOfItem(atPath: path)[.size] as? UInt ?? 0
            return total + size
        }
        XCTAssertEqual(try cache.diskStorage.totalSize(), fileBytes)

        _ = try cache.diskStorage.removeExpiredValues()
        _ = try cache.diskStorage.removeSizeExceededValues()
        XCTAssertEqual(files(in: cache).count, 4)

        cache.clearMemoryCache()
        await cache.removeImages(forKeysMatching: { $0 == "item/0" || $0 == "item/3" })
        XCTAssertEqual(cache.imageCachedType(forKey: "item/0", processorIdentifier: ""), .none)
        XCTAssertEqual(cache.imageCachedType(forKey: "item/3", processorIdentifier: ""), .none)
        XCTAssertEqual(cache.imageCachedType(forKey: "item/1", processorIdentifier: ""), .disk)
        XCTAssertEqual(files(in: cache).count, 2)
    }

    // Files written straight through the disk storage carry no original key and are left alone.
    func testFilesWithoutOriginalKeyAreUntouched() async throws {
        let cache = try makeCache(name: "legacy", root: makeRoot())
        try cache.diskStorage.store(value: makeImage(1).1, forKey: "legacy/1")
        try await store(cache, "new/1", seed: 2)

        let recorder = KeyRecorder()
        await cache.removeImages(forKeysMatching: { key in
            recorder.record(key)
            return true
        })

        XCTAssertEqual(recorder.keys, ["new/1"])
        XCTAssertTrue(cache.diskStorage.isCached(forKey: "legacy/1"))
        XCTAssertEqual(cache.imageCachedType(forKey: "new/1", processorIdentifier: ""), .none)
    }

    // The completion handler runs once, after the removal is done, on the requested queue.
    func testCompletionHandlerVersion() async throws {
        let cache = try makeCache(name: "callback", root: makeRoot())
        try await store(cache, "x/1", seed: 1)
        try await store(cache, "y/1", seed: 2)

        let done = expectation(description: "removal finished")
        done.expectedFulfillmentCount = 1
        done.assertForOverFulfill = true
        cache.removeImages(
            forKeysMatching: { $0.hasPrefix("x/") },
            callbackQueue: .mainAsync
        ) {
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertFalse(cache.diskStorage.isCached(forKey: "x/1"))
            done.fulfill()
        }
        await fulfillment(of: [done], timeout: 10)

        XCTAssertEqual(cache.imageCachedType(forKey: "x/1", processorIdentifier: ""), .none)
        XCTAssertEqual(cache.imageCachedType(forKey: "y/1", processorIdentifier: ""), .memory)
    }

    // Removed keys can be stored again and found again.
    func testStoreAgainAfterRemoval() async throws {
        let cache = try makeCache(name: "again", root: makeRoot())
        try await store(cache, "z/1", seed: 1)
        await cache.removeImages(forKeysMatching: { _ in true })
        XCTAssertEqual(cache.imageCachedType(forKey: "z/1", processorIdentifier: ""), .none)

        try await store(cache, "z/1", seed: 2)
        XCTAssertEqual(cache.imageCachedType(forKey: "z/1", processorIdentifier: ""), .memory)
        cache.clearMemoryCache()
        XCTAssertEqual(cache.imageCachedType(forKey: "z/1", processorIdentifier: ""), .disk)

        await cache.removeImages(forKeysMatching: { $0 == "z/1" })
        XCTAssertEqual(cache.imageCachedType(forKey: "z/1", processorIdentifier: ""), .none)
        XCTAssertTrue(files(in: cache).isEmpty)
    }
}
EOF

swift build --build-tests --disable-automatic-resolution \
  --package-path "$CHECK_DIR/Check" --scratch-path "$CHECK_DIR/build" \
  > "$ARTIFACTS/build.log" 2>&1 \
  || fail "The tests do not compile against the changed ImageCache: the removeImages(forKeysMatching:...) API is missing or has a different signature. See build.log."

swift test --skip-build --disable-automatic-resolution \
  --package-path "$CHECK_DIR/Check" --scratch-path "$CHECK_DIR/build" \
  > "$ARTIFACTS/test.log" 2>&1 \
  || fail "Removing images by key predicate does not behave as required. See test.log for the failed cases."

grep -q "Executed 8 tests, with 0 failures" "$ARTIFACTS/test.log" \
  || fail "Not all 8 removal cases ran and passed. See test.log."

# The existing cache behavior must keep working.
xcodebuild -skipMacroValidation -skipPackagePluginValidation -disableAutomaticPackageResolution \
  -project "$CHECK_DIR/Kingfisher/Kingfisher.xcodeproj" -scheme Kingfisher \
  -destination "platform=macOS" -derivedDataPath "$CHECK_DIR/derived" CODE_SIGNING_ALLOWED=NO \
  -only-testing:KingfisherTests/ImageCacheTests \
  -only-testing:KingfisherTests/DiskStorageTests \
  -only-testing:KingfisherTests/MemoryStorageTests \
  test > "$ARTIFACTS/regression.log" 2>&1 \
  || fail "The existing ImageCache, DiskStorage or MemoryStorage tests fail. See regression.log."
pass
