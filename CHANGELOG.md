# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-02-16

### Added
- Optional adaptive cache policy infrastructure for caching-first tuning (TTL and cache limits)
- New public configuration options for adaptive policy evaluation windows and safety bounds
- Documentation for on-device adaptive policy strategy using Apple-native frameworks

### Changed
- Documentation refreshed across README and guides to align with current async actor-based API usage
- Installation examples standardized on `2.0.0` or later
- Migration guide updated with async `configure` and cache management examples

### Fixed
- Cache management docs now accurately describe preferred async API patterns
- Demo README package URL updated to the published SwiftCache repository
- `clearExpiredCache()` now removes stale disk entries using `diskCacheMaxAge`
- Analytics now track actual source layer hits (memory/disk/network)
- Callback and progressive APIs now wire `CancellationToken` to running tasks for true cancellation

## [2.0.0] - 2025-11-10

### 🎉 Major Rewrite - Swift Concurrency & Design Patterns

This is a **major architectural overhaul** with modern Swift Concurrency and design patterns.

### ⚠️ Breaking Changes
- `SwiftCache` is now an `actor` (thread-safe by design)
- Primary API is now `async/await` (callback API still supported for backward compatibility)
- `UIImageView` extension requires `@MainActor` context
- Removed all GCD (`DispatchQueue`) usage in favor of Swift Concurrency

### ✨ New Features
- **Chain of Responsibility Pattern**: Clean three-tier fallback (Memory → Disk → Network)
- **Strategy Pattern**: Pluggable cache loaders - implement custom backends!
- **macOS Downscaling Support**: Image downscaling now works on macOS, not just iOS
- **Custom Loader API**: `setCustomLoaders(_:)` allows complete customization
- **Swift 6 Ready**: Full `Sendable` conformance, strict concurrency checking
- **Better Performance**: Actors eliminate thread-hopping and GCD overhead

### 🔧 Changed
- **Actor-based architecture**: `SwiftCache`, `CacheLoaderChain`, `CacheAnalytics` are now actors
- **No More `await MainActor.run` blocking**: Proper MainActor isolation
- **Improved async/await**: No more wrapping callbacks with continuations (anti-pattern)
- **Thread-safe CancellationToken**: Uses structured concurrency with locks
- **Better error handling**: Added `.imageNotFound` error case

### 🚀 Improved
- **macOS Support**: First-class support with downscaling, documented in README
- **Extensibility**: Users can plug in Redis, S3, or any custom cache backend
- **Testing**: Easier to mock with strategy pattern
- **Documentation**: New architecture guide explaining all patterns

### 📚 Documentation
- Added `Documentation/architecture-guide.md` with detailed explanation
- Updated README with extensibility examples
- Added macOS downscaling documentation

## [1.0.0] - 2025-11-06

### Added
- Initial release of SwiftCache
- iOS demo app with SwiftUI example
- Three-tier caching system (Memory → Disk → Network)
- TTL (time-to-live) support with automatic expiration
- UIImageView extension for easy integration (`imageView.sc.setImage()`)
- SwiftUI `CachedImage` view
- Async/await APIs for iOS 15+
- Progressive loading (thumbnail → full image)
- Cache analytics and performance metrics
- Cancellable requests with token-based cancellation
- Lifecycle-aware memory management
- LRU disk cache cleanup
- Zero external dependencies
- Comprehensive unit tests
- UIKit and SwiftUI example apps
- Full documentation and migration guide

### Features
- Memory cache with NSCache (50MB default limit)
- Disk cache with FileManager (500MB default limit)
- Network cache with URLCache (200MB default limit)
- Configurable cache limits and TTL
- Automatic cache cleanup on memory warnings
- Background memory reduction
- Cache size tracking
- Performance metrics (hit rate, load times)
- Image downscaling for large images
- Thread-safe operations
- Swift 6 language mode compatibility

### Platforms
- iOS 14.0+
- macOS 11.0+
- tvOS 14.0+
- watchOS 7.0+

