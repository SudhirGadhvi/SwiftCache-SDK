# SwiftCache

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-blue" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange" />
  <img src="https://img.shields.io/badge/license-MIT-green" />
</p>

A modern, lightweight image caching library for iOS and macOS. Built with 100% Apple native APIs—zero dependencies.

## 🌟 Features

- ✅ **Zero Dependencies** - Pure Swift, no third-party frameworks
- ✅ **Lightweight** - Optimized for performance and app size
- ✅ **TTL Support** - Automatic cache expiration with customizable time-to-live
- ✅ **Three-Tier Caching** - Memory → Disk → Network with automatic fallback
- ✅ **Progressive Loading** - Show thumbnails while loading full images
- ✅ **Lifecycle Aware** - Automatically manages memory in background/foreground
- ✅ **Thread Safe** - Built on NSCache and DispatchQueue
- ✅ **Modern Swift** - Async/await support, SwiftUI integration
- ✅ **Cancellable Requests** - Cancel downloads when cells are reused
- ✅ **LRU Eviction** - Automatic cleanup of old cached images
- ✅ **Analytics** - Built-in performance metrics and cache statistics

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
}
```

## 📊 Performance

| Library | Binary Size | Memory Cache | Disk Cache | TTL Support | Progressive Loading | Dependencies |
|---------|-------------|--------------|------------|-------------|---------------------|--------------|
| SwiftCache | 150KB | ✅ | ✅ | ✅ | ✅ | 0 |
| Kingfisher | 500KB | ✅ | ✅ | Limited | ✅ | 0 |
| SDWebImage | 800KB | ✅ | ✅ | ❌ | ✅ | 0 |

## 📖 Documentation

- [Getting Started Guide](Documentation/getting-started.md)
- [Migration from Kingfisher](Documentation/migration-guide.md)
- [Demo App Example](DemoApp/)

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## 📝 License

SwiftCache is released under the MIT License. See [LICENSE](LICENSE) for details.

## 👤 Author

**Sudhir Gadhvi**
- LinkedIn: [Sudhir Gadhvi](https://www.linkedin.com/in/sudhirgadhvi/)

## 🙏 Acknowledgments

Inspired by real-world challenges in building modern iOS apps.

---

⭐️ If you like SwiftCache, give it a star on GitHub!

