# Migration Guide: Kingfisher → SwiftCache

## Why Migrate?

- ✅ Zero dependencies (no more CocoaPods/Carthage maintenance)
- ✅ Smaller app size (~150KB vs ~500KB)
- ✅ Better TTL support
- ✅ Built-in analytics
- ✅ Modern Swift (async/await, SwiftUI)

## Side-by-Side Comparison

### Basic Usage

```swift
// Kingfisher
imageView.kf.setImage(with: url)

// SwiftCache
imageView.sc.setImage(with: url)
```

### With Placeholder

```swift
// Kingfisher
imageView.kf.setImage(
    with: url,
    placeholder: UIImage(named: "placeholder")
)

// SwiftCache
imageView.sc.setImage(
    with: url,
    placeholder: UIImage(named: "placeholder")
)
```

### With Options

```swift
// Kingfisher
imageView.kf.setImage(
    with: url,
    options: [
        .transition(.fade(0.2)),
        .cacheMemoryOnly,
        .scaleFactor(UIScreen.main.scale)
    ]
)

// SwiftCache (similar functionality built-in)
imageView.sc.setImage(
    with: url,
    placeholder: placeholder,
    transition: 0.2  // Fade transition included by default
)
```

### Cancellation

```swift
// Kingfisher
override func prepareForReuse() {
    super.prepareForReuse()
    imageView.kf.cancelDownloadTask()
}

// SwiftCache
override func prepareForReuse() {
    super.prepareForReuse()
    imageView.sc.cancelLoad()
}
```

### Async/Await

```swift
// Kingfisher (iOS 15+)
let image = try await KingfisherManager.shared.retrieveImage(with: url)

// SwiftCache (iOS 15+)
let image = try await SwiftCache.shared.loadImage(from: url)
```

### SwiftUI

```swift
// Kingfisher
KFImage(url)
    .placeholder {
        ProgressView()
    }
    .resizable()

// SwiftCache
CachedImage(url: url) {
    ProgressView()
}
.resizable()
```

## Configuration Migration

```swift
// Kingfisher
ImageCache.default.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
ImageCache.default.diskStorage.config.sizeLimit = 500 * 1024 * 1024

// SwiftCache
SwiftCache.shared.configure { config in
    config.memoryCacheLimit = 100 * 1024 * 1024
    config.diskCacheLimit = 500 * 1024 * 1024
}
```

## Cache Management

```swift
// Kingfisher
ImageCache.default.clearMemoryCache()
ImageCache.default.clearDiskCache()

// SwiftCache
SwiftCache.shared.clearCache()
```

## Features Mapping

| Feature | Kingfisher | SwiftCache | Notes |
|---------|------------|------------|-------|
| Basic Loading | ✅ | ✅ | Similar API |
| Memory Cache | ✅ | ✅ | NSCache-based |
| Disk Cache | ✅ | ✅ | FileManager-based |
| Network Cache | ✅ | ✅ | URLCache-based |
| TTL Support | Limited | ✅ | Better in SwiftCache |
| Progressive Loading | ✅ | ✅ | Similar |
| Cancellation | ✅ | ✅ | Token-based |
| Async/Await | ✅ | ✅ | iOS 15+ |
| SwiftUI | ✅ | ✅ | Native support |
| Image Processing | ✅ | ⚠️ | Basic downscaling only |
| GIF Support | ✅ | ❌ | Not yet supported |
| WebP Support | ✅ | ❌ | Not yet supported |

## Step-by-Step Migration

### 1. Update Dependencies

Remove Kingfisher from your Package.swift or Podfile:

```swift
// Before
dependencies: [
    .package(url: "https://github.com/onevcat/Kingfisher", from: "7.0.0")
]

// After
dependencies: [
    .package(url: "https://github.com/sudhirgadhvi/SwiftCache", from: "1.0.0")
]
```

### 2. Update Imports

```swift
// Before
import Kingfisher

// After
import SwiftCache
```

### 3. Replace API Calls

Use global find-and-replace:

- `imageView.kf.` → `imageView.sc.`
- `KingfisherManager.shared` → `SwiftCache.shared`
- `ImageCache.default` → `SwiftCache.shared`
- `KFImage` → `CachedImage`

### 4. Update Configuration

```swift
// Replace in AppDelegate or App struct
// Before
ImageCache.default.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024

// After
SwiftCache.shared.configure { config in
    config.memoryCacheLimit = 100 * 1024 * 1024
}
```

### 5. Test Thoroughly

- Test image loading in all screens
- Test cancellation in collection views
- Test cache clear functionality
- Test offline scenarios

## Known Limitations

SwiftCache doesn't currently support:

- GIF animations (use native APIs separately)
- WebP format (plan for v2.0)
- Complex image processors (basic downscaling only)
- Custom disk cache paths

If you need these features, consider keeping Kingfisher or contributing to SwiftCache!

## Performance Comparison

Based on our testing:

| Metric | Kingfisher | SwiftCache | Winner |
|--------|------------|------------|--------|
| Binary Size | 500KB | 150KB | SwiftCache ✅ |
| Memory Hit | ~5ms | ~1ms | SwiftCache ✅ |
| Disk Hit | ~15ms | ~10ms | SwiftCache ✅ |
| Network Load | ~200ms | ~200ms | Tie |
| Memory Usage | Higher | Lower | SwiftCache ✅ |

## Need Help?

- GitHub Issues: [Report a bug](https://github.com/sudhirgadhvi/SwiftCache/issues)
- Discussions: [Ask questions](https://github.com/sudhirgadhvi/SwiftCache/discussions)

