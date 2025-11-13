# Getting Started with SwiftCache

## Installation

### Swift Package Manager

Add SwiftCache to your project using Xcode:

1. File → Add Package Dependencies
2. Enter: `https://github.com/SudhirGadhvi/SwiftCache-SDK`
3. Select version: `1.0.0` or later

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/SudhirGadhvi/SwiftCache-SDK", from: "1.0.0")
]
```

## Basic Usage

### UIKit

```swift
import SwiftCache

// Simple image loading
imageView.sc.setImage(with: url)

// With placeholder
imageView.sc.setImage(
    with: url,
    placeholder: UIImage(systemName: "photo")
)

// With completion handler
imageView.sc.setImage(with: url) { result in
    switch result {
    case .success(let image):
        print("Loaded: \(image.size)")
    case .failure(let error):
        print("Error: \(error)")
    }
}

// Async/await (iOS 15+)
Task {
    do {
        let image = try await imageView.sc.setImage(with: url)
        print("Loaded: \(image.size)")
    } catch {
        print("Error: \(error)")
    }
}
```

### SwiftUI

**Modern SwiftUI (iOS 15+):**

```swift
import SwiftUI
import SwiftCache

struct MyView: View {
    let imageURL: URL
    
    var body: some View {
        NavigationStack {
            CachedImage(url: imageURL) {
                ProgressView()
            }
            .frame(width: 300, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .task {
            // Configure cache when view appears
            await SwiftCache.shared.configure { config in
                config.enableAnalytics = true
                config.enableProgressiveLoading = true
            }
        }
    }
}
```

**Key features:**
- Uses modern `.task` modifier instead of `.onAppear` + `Task`
- Automatic cancellation when view disappears
- Task automatically restarts when URL changes
- Native SwiftUI async/await integration

## Configuration

Customize SwiftCache behavior using modern async/await:

```swift
// Modern approach: Use .task modifier
.task {
    await SwiftCache.shared.configure { config in
        // Memory cache settings
        config.memoryCacheLimit = 100 * 1024 * 1024  // 100MB
        config.memoryCacheCountLimit = 150            // 150 images
        
        // Disk cache settings
        config.diskCacheLimit = 1024 * 1024 * 1024   // 1GB
        config.diskCacheMaxAge = 7 * 24 * 60 * 60     // 7 days
        
        // TTL settings
        config.defaultTTL = 3600                      // 1 hour
        
        // Features
        config.enableProgressiveLoading = true
        config.enableAnalytics = true
        
        // Memory management
        config.reduceMemoryInBackground = true
        config.backgroundMemoryCacheLimit = 20 * 1024 * 1024  // 20MB
    }
}

// Or in AppDelegate/App struct
Task {
    await SwiftCache.shared.configure { config in
        // ... configuration
    }
}
```

## Progressive Loading

Show thumbnails first for better UX:

```swift
// UIKit
imageView.sc.setImageProgressive(
    with: fullImageURL,
    thumbnailURL: thumbnailURL
)

// Or let SwiftCache generate thumbnail from full image
imageView.sc.setImageProgressive(with: fullImageURL)
```

## Cache Management

```swift
// UIKit - Clear all caches
SwiftCache.shared.clearCache()

// Clear only expired entries
SwiftCache.shared.clearExpiredCache()

// SwiftUI - Use async/await in task or button action
Button("Clear Cache") {
    SwiftCache.shared.clearCache()
}

Button("Clear Expired") {
    SwiftCache.shared.clearExpiredCache()
}

// Get cache size (async)
.task {
    let (memorySize, diskSize) = await SwiftCache.shared.getCacheSize()
    print("Memory: \(memorySize), Disk: \(diskSize)")
}

// Get performance metrics (async)
.task {
    let metrics = await SwiftCache.shared.getMetrics()
    print("Hit rate: \(metrics.hitRate * 100)%")
}
```

## Advanced Usage

### Custom Cache Keys

```swift
// Use custom cache key instead of URL
imageView.sc.setImage(
    with: url,
    cacheKey: "user_avatar_\(userID)"
)
```

### Custom TTL

```swift
// Cache for 10 minutes
imageView.sc.setImage(
    with: url,
    ttl: 600
)
```

### Prefetching

```swift
// Prefetch images for better UX
let urls = [url1, url2, url3]
SwiftCache.shared.prefetch(urls: urls)
```

### Cancellation

```swift
// Cancel ongoing request
let token = imageView.sc.setImage(with: url)
// Later...
token?.cancel()

// Or cancel in prepareForReuse
override func prepareForReuse() {
    super.prepareForReuse()
    imageView.sc.cancelLoad()
}
```

## Best Practices

### Modern SwiftUI (iOS 15+)

1. **Use `NavigationStack` instead of `NavigationView`**
   ```swift
   NavigationStack {
       // Your content
   }
   ```

2. **Use `.task` instead of `.onAppear` for async work**
   ```swift
   .task {
       await loadData()
   }
   ```

3. **Use `LabeledContent` for label-value pairs**
   ```swift
   LabeledContent("Cache Size") {
       Text("\(size) MB")
   }
   ```

4. **Use `.clipShape()` instead of `.cornerRadius()`**
   ```swift
   .clipShape(RoundedRectangle(cornerRadius: 8))
   ```

5. **Use `.foregroundStyle()` instead of `.foregroundColor()`**
   ```swift
   .foregroundStyle(.secondary)
   ```

### General Best Practices

1. **Configure Once**: Set up SwiftCache in your AppDelegate or App struct
2. **Use TTL**: Set appropriate TTL based on your content freshness requirements
3. **Monitor Metrics**: Enable analytics in development to optimize cache settings
4. **Clear Cache**: Clear cache on logout or when storage is low
5. **Prefetch**: Use prefetch for known image lists (e.g., upcoming screen)

## Next Steps

- Check out the [Demo App](../DemoApp/) for complete examples
- [Migration from Kingfisher](migration-guide.md)
- Browse the source code for detailed API documentation

