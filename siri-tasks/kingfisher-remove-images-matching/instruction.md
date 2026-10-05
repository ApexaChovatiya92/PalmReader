# ImageCache Key-Matching Removal Requirements

----------------------------------------------------------------
PART 1 · What to change
Add a way to ImageCache to remove all images whose key matches a condition.

----------------------------------------------------------------
PART 2 · The new API

```swift
open func removeImages(
    forKeysMatching predicate: @escaping @Sendable (String) -> Bool,
    fromMemory: Bool = true,
    fromDisk: Bool = true,
    callbackQueue: CallbackQueue = .untouch,
    completionHandler: (@Sendable () -> Void)? = nil
)

open func removeImages(
    forKeysMatching predicate: @escaping @Sendable (String) -> Bool,
    fromMemory: Bool = true,
    fromDisk: Bool = true
) async
```

----------------------------------------------------------------
PART 3 · How it must behave
    [ ] Predicate gets the original forKey value; keys may contain @.
    [ ] Matching key removes images for all processor IDs; others remain.
    [ ] fromMemory / fromDisk behave like removeImage(forKey:).
    [ ] Disk removal works after relaunch/new cache instance and memory clear.
    [ ] Direct diskStorage files stay untouched; predicate isn’t called for them.
    [ ] Removing expired files or files over the size limit must not break later removal.
    [ ] Completion runs once after removal on callbackQueue; async returns after removal.
    [ ] Removed keys can be stored and retrieved again.
    [ ] No extra files, including hidden files, in the cache folder.

----------------------------------------------------------------
PART 4 · What must keep working
    [ ] Everything ImageCache, DiskStorage and MemoryStorage do today.
    [ ] Same minimum OS versions (iOS 15, macOS 12). No new dependencies.
