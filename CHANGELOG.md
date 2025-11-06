# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-06

### Added
- Initial release of SwiftCache
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

### Platforms
- iOS 14.0+
- macOS 11.0+
- tvOS 14.0+
- watchOS 7.0+

## [Unreleased]

### Planned for v1.1.0
- Combine support
- GIF animation support
- WebP format support
- Custom image processors
- Network reachability awareness

### Planned for v2.0.0
- Advanced image transformations (resize, crop, filters)
- Video thumbnail caching
- CloudKit sync support
- Custom disk cache paths

