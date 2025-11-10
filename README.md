# SwiftCache

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-blue" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange" />
  <img src="https://img.shields.io/badge/license-MIT-green" />
</p>

A modern, lightweight image caching library for iOS and macOS. Built with 100% Apple native APIs—zero dependencies.

<p align="center">
  <img src="assets/demo-app.png" alt="SwiftCache Demo" width="300"/>
  <img src="assets/stats-screen.png" alt="Performance Stats" width="300"/>
</p>

## 🌟 Features

- ✅ **Zero Dependencies** - Pure Swift, no third-party frameworks
- ✅ **Lightweight** - Optimized for performance and app size (~150KB)
- ✅ **Cross-Platform** - Full support for iOS, macOS, tvOS, and watchOS
- ✅ **TTL Support** - Automatic cache expiration with customizable time-to-live
- ✅ **Three-Tier Caching** - Memory → Disk → Network with Chain of Responsibility pattern
- ✅ **Progressive Loading** - Show thumbnails while loading full images
- ✅ **Automatic Downscaling** - Reduce memory usage on both iOS and macOS
- ✅ **Lifecycle Aware** - Automatically manages memory in background/foreground
- ✅ **Thread Safe** - Built with Swift Concurrency (actors) and async/await
- ✅ **Modern Swift** - Actor-based architecture, no GCD mixing
- ✅ **Extensible** - Strategy pattern allows custom cache implementations
- ✅ **Cancellable Requests** - Cancel downloads when cells are reused
- ✅ **LRU Eviction** - Automatic cleanup of old cached images
- ✅ **Analytics** - Built-in performance metrics and cache statistics
- ✅ **Swift 6 Ready** - Full Sendable conformance and strict concurrency

## 📦 Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/SudhirGadhvi/SwiftCache-SDK", from: "1.0.0")
]
```

### CocoaPods

```ruby
pod 'SwiftCache', '~> 1.0'
```

## 🚀 Quick Start

### UIKit

```swift
import SwiftCache

// Simple usage
imageView.sc.setImage(with: url)

// With placeholder
imageView.sc.setImage(with: url, placeholder: UIImage(systemName: "photo"))

// With completion
imageView.sc.setImage(with: url) { result in
    switch result {
    case .success(let image):
        print("Image loaded: \(image.size)")
    case .failure(let error):
        print("Failed: \(error)")
    }
}

// Async/await (iOS 15+)
Task {
    do {
        let image = try await imageView.sc.setImage(with: url)
        print("Image loaded: \(image.size)")
    } catch {
        print("Failed: \(error)")
    }
}
```

### SwiftUI

```swift
import SwiftCache

struct ContentView: View {
    var body: some View {
        CachedImage(url: imageURL)
            .placeholder {
                ProgressView()
            }
            .transition(.opacity)
            .frame(width: 300, height: 300)
    }
}
```

## ⚙️ Configuration

```swift
// Configure global settings
SwiftCache.shared.configure { config in
    config.memoryCacheLimit = 100 * 1024 * 1024  // 100MB
    config.diskCacheLimit = 1024 * 1024 * 1024   // 1GB
    config.defaultTTL = 86400                     // 24 hours
    config.enableAnalytics = true
    
    // Enable automatic downscaling (works on iOS and macOS)
    config.maxImageDimension = 2048              // Max 2048px on longest side
}
```

## 🔌 Extensibility with Custom Loaders

SwiftCache uses the **Strategy Pattern** to allow custom implementations for each cache layer:

```swift
// Create a custom memory loader
class MyCustomMemoryLoader: CacheLoader {
    func load(key: String, url: URL, ttl: TimeInterval) async -> SCImage? {
        // Your custom memory cache implementation
    }
    
    func store(image: SCImage, key: String, ttl: TimeInterval) async {
        // Your custom storage logic
    }
    
    func clear() async {
        // Your custom clear logic
    }
}

// Set custom loaders
await SwiftCache.shared.setCustomLoaders([
    MyCustomMemoryLoader(),
    MyCustomDiskLoader(),
    MyCustomNetworkLoader()
])
```

This makes SwiftCache incredibly flexible - use your own cache backends, network layers, or storage mechanisms!

## 📊 Performance

| Library | Binary Size | Memory Cache | Disk Cache | TTL Support | Progressive Loading | Dependencies |
|---------|-------------|--------------|------------|-------------|---------------------|--------------|
| SwiftCache | 150KB | ✅ | ✅ | ✅ | ✅ | 0 |
| Kingfisher | 500KB | ✅ | ✅ | Limited | ✅ | 0 |
| SDWebImage | 800KB | ✅ | ✅ | ❌ | ✅ | 0 |

## 📖 Documentation

- [Getting Started Guide](Documentation/getting-started.md)
- [Migration from Kingfisher](Documentation/migration-guide.md)
- [Architecture Guide](Documentation/architecture-guide.md)
- [Demo App Example](DemoApp/)

## 🗺️ Roadmap

### v2.1.0 (Next Release)
- [ ] **Combine Support** - Publishers for reactive programming
- [ ] **GIF Animation Support** - Animated image caching
- [ ] **WebP Format Support** - Modern image format
- [ ] **Custom Image Processors** - Transform images before caching
- [ ] **Network Reachability** - Pause downloads when offline

### v2.2.0
- [ ] **Prefetching API** - Intelligent prefetch with priority
- [ ] **Image Placeholders** - Blurhash/ThumbHash support
- [ ] **Cache Warming** - Preload frequently used images
- [ ] **Memory Pressure Monitoring** - Adaptive cache limits

### v3.0.0 (Major)
- [ ] **Advanced Transformations** - Resize, crop, filters, effects
- [ ] **Video Thumbnail Caching** - Extract and cache video frames
- [ ] **CloudKit Sync** - Sync cache across devices
- [ ] **Custom Disk Paths** - Multi-level disk cache
- [ ] **SwiftData Integration** - Modern persistence layer

### Future Considerations
- [ ] **AVIF Format Support** - Next-gen image format
- [ ] **HEIF/HEIC Optimization** - Native Apple format improvements
- [ ] **Background Downloads** - URLSession background transfer
- [ ] **Smart Cache Eviction** - ML-based prediction
- [ ] **CDN Integration** - Cloudflare, CloudFront adapters

Want a feature? [Open an issue](https://github.com/SudhirGadhvi/SwiftCache-SDK/issues)!

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## 📝 License

SwiftCache is released under the MIT License. See [LICENSE](LICENSE) for details.

## 👤 Author

**Sudhir Gadhvi**

- GitHub: [@SudhirGadhvi](https://github.com/SudhirGadhvi)
- LinkedIn: [Sudhir Gadhvi](https://www.linkedin.com/in/sudhirgadhvi/)

## 🙏 Acknowledgments

Inspired by real-world challenges in building modern iOS apps.

---

⭐️ If you like SwiftCache, give it a star on GitHub!

