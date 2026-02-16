# SwiftCache

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-blue" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange" />
  <img src="https://img.shields.io/badge/license-MIT-green" />
</p>

A modern, lightweight image caching library for iOS and macOS. Built with 100% Apple native APIs—zero dependencies.

<p align="center">
  <img src="https://github.com/user-attachments/assets/df1f4b15-4eff-42ce-9264-b3f072f8edc2" alt="demo-app" width="45%" />
  <img src="https://github.com/user-attachments/assets/021c9d2e-280a-4f8c-9db6-5896cd4eeb11" alt="stats-screen" width="45%" />
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
- ✅ **Adaptive Cache Policy** - Optional on-device policy tuning for TTL/cache limits
- ✅ **Swift 6 Ready** - Full Sendable conformance and strict concurrency

## 📦 Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/SudhirGadhvi/SwiftCache-SDK", from: "2.1.0")
]
```

### CocoaPods

```ruby
pod 'SwiftCacheSDK', '~> 2.1'
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

**Modern SwiftUI (iOS 15+):**

```swift
import SwiftUI
import SwiftCache

struct ContentView: View {
    var body: some View {
        NavigationStack {
            CachedImage(url: imageURL) {
                ProgressView()
            }
            .frame(width: 300, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
```

**Key modern features:**
- Uses `.task(id:)` for automatic cancellation and restart on URL changes
- No manual `MainActor.run` calls - proper SwiftUI integration
- Follows modern SwiftUI patterns (iOS 15+)

## ⚙️ Configuration

```swift
// Configure global settings
Task {
    await SwiftCache.shared.configure { config in
        config.memoryCacheLimit = 100 * 1024 * 1024  // 100MB
        config.diskCacheLimit = 1024 * 1024 * 1024   // 1GB
        config.defaultTTL = 86400                     // 24 hours
        config.enableAnalytics = true
        
        // Enable automatic downscaling (works on iOS and macOS)
        config.maxImageDimension = 2048              // Max 2048px on longest side

        // Optional: adaptive cache policy (caching-first intelligence)
        config.enableAdaptiveCachePolicy = true
        config.adaptivePolicyEvaluationInterval = 30 * 60
        config.adaptivePolicyMinimumRequests = 60
    }
}
```

## 🧠 Adaptive Cache Policy (Optional)

SwiftCache can tune cache settings based on real usage telemetry to improve hit rates and reduce reload costs.

**How it works:**
- Collects cache telemetry in a rolling window (hits/misses/load time)
- Evaluates policy periodically (not per request)
- Applies bounded configuration changes (TTL + cache limits)
- Falls back to static config when adaptive mode is disabled

```swift
Task {
    await SwiftCache.shared.configure { config in
        config.enableAdaptiveCachePolicy = true
        config.adaptivePolicyEvaluationInterval = 30 * 60      // every 30 minutes
        config.adaptivePolicyMinimumRequests = 60               // minimum window size
        config.adaptivePolicyMinTTL = 5 * 60                   // 5 minutes
        config.adaptivePolicyMaxTTL = 7 * 24 * 60 * 60         // 7 days
    }
}
```

You can also provide a custom adaptive policy engine if you want to plug in app-specific or on-device Foundation Models logic.

### Understanding the Stats Screen

The adaptive section in the demo screen shows:

- **Adaptive Window**: A rolling telemetry window used by adaptive policy. It tracks recent request behavior until the next policy evaluation or reset.
- **Window Requests**: Number of requests collected in the current adaptive window.
- **Window Hit Rate**: Overall successful loads across all layers (memory + disk + network).  
  On first run, this can be high even when cache is cold because network responses are successful loads.
- **Window Cache Hit**: Local cache-only hit rate (memory + disk). This is the key metric for cache efficiency.
- **Window Miss Rate**: Requests that failed to load.
- **Avg Load Time**: Average response time in the adaptive window.
- **Evaluate Adaptive Policy Now**: Forces an immediate policy evaluation using current window telemetry.

### How Developers Should Use Adaptive Policy

1. Start with your normal cache configuration and enable adaptive policy.
2. Use app flows that represent real usage (feeds, detail pages, repeated scrolling).
3. Compare behavior with adaptive policy **off vs on**.
4. Watch **Window Cache Hit** over warm cycles. This is the most important cache KPI.
5. Tune bounds (`adaptivePolicyMinTTL`, `adaptivePolicyMaxTTL`, memory/disk limits) to match your content freshness needs.

> Note: `getCacheSize().memory` currently reflects configured memory cache capacity, not precise live memory usage.

## 🔌 Extensibility with Custom Loaders

SwiftCache uses the **Strategy Pattern** to allow custom implementations for each cache layer:

```swift
// Create a custom loader (must be an actor)
actor MyCustomMemoryLoader: CacheLoader {
    func load(key: String, url: URL, ttl: TimeInterval) async -> SCImage? {
        // Your custom memory cache implementation
        return nil
    }
    
    func store(image: SCImage, key: String, ttl: TimeInterval) async {
        // Your custom storage logic
    }
    
    func clear() async {
        // Your custom clear logic
    }
}

// Set custom loaders (async call)
Task {
    await SwiftCache.shared.setCustomLoaders([
        MyCustomMemoryLoader(),
        MyCustomDiskLoader(),
        MyCustomNetworkLoader()
    ])
}
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

## 🗺️ Release Highlights

### ✅ v2.1.0 (Released - February 2026)

**Adaptive Caching & On-Device Intelligence**
- [x] **Adaptive Cache Policy** - Optional telemetry-driven tuning of TTL and cache limits
- [x] **Foundation Models Integration Point** - Pluggable on-device policy engine for Apple Intelligence-capable devices
- [x] **Layer-Accurate Analytics** - Metrics now track memory, disk, and network source layers correctly
- [x] **Real Cancellation Wiring** - Callback/progressive tokens cancel running tasks
- [x] **Expired Cache Cleanup** - `clearExpiredCache()` removes stale disk entries using `diskCacheMaxAge`

### ✅ v2.0.0 (Released - November 2025)

**Major Architecture Rewrite - Swift Concurrency & Design Patterns**
- [x] **Actor-based architecture** - Pure Swift Concurrency
- [x] **Chain of Responsibility pattern** - Clean cache fallback
- [x] **Strategy pattern** - Pluggable custom loaders
- [x] **Async/await native APIs** - Modern Swift
- [x] **macOS downscaling support** - Feature parity with iOS
- [x] **Custom loader API** - Extensibility for Redis, S3, etc.
- [x] **Granular metrics** - Per-layer performance tracking
- [x] **Swift 6 ready** - Full Sendable conformance
- [x] **Removed all GCD** - No DispatchQueue mixing
- [x] **Fixed MainActor blocking** - Proper isolation
- [x] **Thread-safe by design** - Compiler-enforced safety
- [x] **Backward compatible** - Callback APIs maintained
- [x] **Comprehensive tests** - 11 tests covering all features
- [x] **Architecture guide** - Deep dive documentation

### ✅ v1.0.0 (Released - November 2025)

**Initial Release**
- [x] Three-tier caching system (Memory → Disk → Network)
- [x] TTL (time-to-live) support with automatic expiration
- [x] UIImageView extension for easy integration
- [x] SwiftUI `CachedImage` view
- [x] Callback-based APIs
- [x] Progressive loading (thumbnail → full image)
- [x] Cache analytics and performance metrics
- [x] Cancellable requests with token-based cancellation
- [x] Lifecycle-aware memory management
- [x] LRU disk cache cleanup
- [x] Cross-platform support (iOS, macOS, tvOS, watchOS)
- [x] Zero external dependencies
- [x] Image downscaling (iOS only)

For current and upcoming changes, see [CHANGELOG.md](CHANGELOG.md).

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

⭐️ If you like SwiftCache, give it a star!

