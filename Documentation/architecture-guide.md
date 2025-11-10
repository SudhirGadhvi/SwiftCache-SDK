# Architecture Guide

## Overview

SwiftCache v2.0 has been completely rewritten to use **modern Swift Concurrency** with a **Chain of Responsibility** and **Strategy Pattern** architecture.

## Architecture Patterns

### 1. Strategy Pattern (CacheLoader Protocol)

Each cache layer (Memory, Disk, Network) implements the `CacheLoader` protocol:

```swift
public protocol CacheLoader: Sendable {
    func load(key: String, url: URL, ttl: TimeInterval) async -> SCImage?
    func store(image: SCImage, key: String, ttl: TimeInterval) async
    func clear() async
}
```

**Benefits:**
- Users can provide custom implementations
- Easy to test (mock loaders)
- Extensible for custom backends (Redis, S3, etc.)

### 2. Chain of Responsibility Pattern

The `CacheLoaderChain` actor tries each loader in sequence:
1. Memory → Fast, check first
2. Disk → Medium speed, persistent
3. Network → Slow, fallback

If an image is found in a later layer (e.g., Disk), it's automatically promoted to earlier layers (Memory).

```swift
public actor CacheLoaderChain {
    private var loaders: [CacheLoader]
    
    public func load(key: String, url: URL, ttl: TimeInterval) async -> Result<SCImage, SwiftCacheError> {
        for (index, loader) in loaders.enumerated() {
            if let image = await loader.load(key: key, url: url, ttl: ttl) {
                // Promote to previous layers
                for previousIndex in 0..<index {
                    await loaders[previousIndex].store(image: image, key: key, ttl: ttl)
                }
                return .success(image)
            }
        }
        return .failure(.imageNotFound)
    }
}
```

### 3. Swift Concurrency (Actors)

**No More GCD!** The old implementation mixed `DispatchQueue` with async/await, which:
- Created thread-hopping overhead
- Made code hard to reason about
- Blocked MainActor unnecessarily with `await MainActor.run`

**New Implementation:**
- `SwiftCache` is an **actor** (thread-safe by default)
- `CacheLoaderChain` is an **actor**
- `CacheAnalytics` is an **actor**
- `MemoryLoader` is an **actor** (though NSCache is already thread-safe)
- `DiskLoader` is an **actor** (protects file system access)
- `NetworkLoader` is an **actor** (uses native `URLSession.data(for:)`)

**MainActor Usage:**
- Only UI components are `@MainActor` (`SwiftCacheImageViewWrapper`)
- No blocking `await MainActor.run` calls
- Automatic context switching when returning to MainActor

## Key Improvements

### 1. Proper Async/Await

**Old (WRONG):**
```swift
await MainActor.run {
    imageView.image = placeholder  // BLOCKS MainActor!
}

let image = try await withCheckedThrowingContinuation { continuation in
    SwiftCache.shared.loadImage(...) { result in
        continuation.resume(with: result)  // Wrapping callbacks is an anti-pattern
    }
}
```

**New (CORRECT):**
```swift
@MainActor
public func setImage(...) async throws -> UIImage {
    // Already on MainActor, no await needed
    imageView.image = placeholder
    
    // This suspends and runs on background actor
    let image = try await SwiftCache.shared.loadImage(from: url)
    
    // Automatically back on MainActor
    imageView.image = image
    return image
}
```

### 2. macOS Support for Downscaling

**Old:** Only iOS had downscaling (UIGraphicsImageRenderer)

**New:** Both platforms supported:
```swift
#if canImport(UIKit)
private func downscaleImageUIKit(_ image: UIImage, maxDimension: CGFloat) async -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { context in
        image.draw(in: CGRect(origin: .zero, size: newSize))
    }
}
#elseif canImport(AppKit)
private func downscaleImageAppKit(_ image: NSImage, maxDimension: CGFloat) async -> NSImage {
    let scaledImage = NSImage(size: newSize)
    scaledImage.lockFocus()
    image.draw(in: destRect, from: sourceRect, operation: .copy, fraction: 1.0)
    scaledImage.unlockFocus()
    return scaledImage
}
#endif
```

### 3. Sendable Conformance (Swift 6 Ready)

All types that cross actor boundaries are `Sendable`:
- `CacheLoader` protocol
- `SwiftCacheError` enum
- `CacheMetrics` struct
- `CancellationToken` (with `@unchecked Sendable` + NSLock)

### 4. Thread-Safe CancellationToken

**Old:** Used `URLSessionDataTask` directly
**New:** Uses Swift structured concurrency with locks

```swift
public final class CancellationToken: @unchecked Sendable {
    private let lock = NSLock()
    private var _isCancelled: Bool = false
    private var task: Task<Void, Never>?
    
    public func cancel() {
        lock.lock()
        _isCancelled = true
        let taskToCancel = task
        lock.unlock()
        
        taskToCancel?.cancel()
    }
}
```

## Migration Guide (v1 → v2)

### Breaking Changes

1. **SwiftCache is now an actor**
   ```swift
   // Old
   SwiftCache.shared.clearCache()
   
   // New
   await SwiftCache.shared.clearCache()
   // Or use synchronous wrapper (not recommended)
   SwiftCache.shared.clearCache()  // Fires async Task internally
   ```

2. **Primary API is now async**
   ```swift
   // Old
   SwiftCache.shared.loadImage(from: url) { result in
       // handle result
   }
   
   // New (preferred)
   do {
       let image = try await SwiftCache.shared.loadImage(from: url)
   } catch {
       // handle error
   }
   
   // Legacy callback API still supported
   ```

3. **UIImageView extension uses @MainActor**
   ```swift
   // Old
   imageView.sc.setImage(with: url)  // Works anywhere
   
   // New
   await imageView.sc.setImage(with: url)  // Must be on MainActor
   // Or use Task if not already on MainActor
   Task { @MainActor in
       try await imageView.sc.setImage(with: url)
   }
   ```

### Non-Breaking (Backward Compatible)

- Callback-based APIs still work
- Synchronous wrappers provided for convenience (internally use Tasks)

## Performance Considerations

### Actors vs Locks

**Actors are NOT slower than locks!**
- Actors use efficient queuing
- No context switching overhead for same-actor calls
- Better than GCD for structured concurrency

### When to Use `nonisolated`

For functions that don't need actor isolation:
```swift
public actor SwiftCache {
    // Called from non-actor context frequently
    public nonisolated func loadImage(..., completion: @escaping (Result) -> Void) {
        Task {
            // Switch to actor context only when needed
            let result = await self.loadImage(...)
            completion(result)
        }
    }
}
```

## Testing Custom Loaders

```swift
class MockMemoryLoader: CacheLoader {
    var storedImages: [String: SCImage] = [:]
    
    func load(key: String, url: URL, ttl: TimeInterval) async -> SCImage? {
        return storedImages[key]
    }
    
    func store(image: SCImage, key: String, ttl: TimeInterval) async {
        storedImages[key] = image
    }
    
    func clear() async {
        storedImages.removeAll()
    }
}

// Use in tests
await SwiftCache.shared.setCustomLoaders([
    MockMemoryLoader(),
    MockDiskLoader(),
    MockNetworkLoader()
])
```

## FAQ

**Q: Why actors instead of just making everything MainActor?**
A: MainActor should only be used for UI code. Cache operations are CPU/IO intensive and shouldn't block the UI thread.

**Q: Why not use locks instead of actors?**
A: Actors integrate better with Swift Concurrency, provide automatic isolation, and prevent data races at compile time.

**Q: Is backward compatibility maintained?**
A: Yes! Callback-based APIs and synchronous wrappers are provided. Migration to async/await is recommended but not required.

**Q: What about watchOS/tvOS?**
A: Fully supported! The actor-based architecture works across all Apple platforms.

## Conclusion

SwiftCache v2.0 is a complete rewrite that:
- ✅ Fixes async/await misuse
- ✅ Removes GCD/actor mixing
- ✅ Implements Chain of Responsibility + Strategy patterns
- ✅ Adds macOS downscaling support
- ✅ Is Swift 6 ready (full Sendable conformance)
- ✅ Provides extensibility through custom loaders

A modern, well-architected image caching library with backward compatibility!



