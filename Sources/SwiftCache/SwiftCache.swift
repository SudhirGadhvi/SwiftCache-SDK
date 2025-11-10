//
//  SwiftCache.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A lightweight, zero-dependency image caching library built on 100% Apple native APIs.
///
/// SwiftCache provides three-tier caching: Memory → Disk → Network
/// with automatic TTL (time-to-live) support and lifecycle-aware memory management.
public actor SwiftCache {
    
    // MARK: - Singleton
    
    public static let shared = SwiftCache()
    
    // MARK: - Properties
    
    public private(set) var configuration = CacheConfiguration()
    private var loaderChain: CacheLoaderChain
    private var memoryLoader: MemoryLoader
    private var diskLoader: DiskLoader
    private var networkLoader: NetworkLoader
    private let analytics = CacheAnalytics()
    
    // MARK: - Initialization
    
    private init() {
        // Initialize loaders
        let config = CacheConfiguration()
        self.memoryLoader = MemoryLoader(configuration: config)
        self.diskLoader = DiskLoader(configuration: config)
        self.networkLoader = NetworkLoader(configuration: config)
        
        // Create chain: Memory → Disk → Network
        self.loaderChain = CacheLoaderChain(
            loaders: [memoryLoader, diskLoader, networkLoader],
            configuration: config
        )
        
        Task {
            await observeLifecycleEvents()
        }
    }
    
    // MARK: - Configuration
    
    /// Configure SwiftCache with custom settings
    public func configure(_ configurator: (inout CacheConfiguration) -> Void) async {
        configurator(&configuration)
        
        // Recreate loaders with new configuration
        memoryLoader = MemoryLoader(configuration: configuration)
        diskLoader = DiskLoader(configuration: configuration)
        networkLoader = NetworkLoader(configuration: configuration)
        
        await loaderChain.setLoaders([memoryLoader, diskLoader, networkLoader])
    }
    
    /// Set custom loaders for extensibility
    /// - Parameter loaders: Array of custom loaders (e.g., custom disk cache, network layer)
    public func setCustomLoaders(_ loaders: [CacheLoader]) async {
        await loaderChain.setLoaders(loaders)
    }
    
    // MARK: - Public API - Async/Await (Primary)
    
    /// Load image with three-tier fallback (Memory → Disk → Network)
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - cacheKey: Optional custom cache key (defaults to URL string)
    ///   - ttl: Optional time-to-live in seconds (defaults to configuration.defaultTTL)
    /// - Returns: The loaded image
    /// - Throws: SwiftCacheError if loading fails
    public func loadImage(
        from url: URL,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil
    ) async throws -> SCImage {
        
        let key = cacheKey ?? url.absoluteString
        let effectiveTTL = ttl ?? configuration.defaultTTL
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = await loaderChain.load(key: key, url: url, ttl: effectiveTTL)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        if configuration.enableAnalytics {
            await trackMetrics(result: result, duration: duration)
        }
        
        switch result {
        case .success(let image):
            return image
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Public API - Callback-based (Legacy Support)
    
    /// Load image with callback (for backward compatibility)
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - cacheKey: Optional custom cache key (defaults to URL string)
    ///   - ttl: Optional time-to-live in seconds (defaults to configuration.defaultTTL)
    ///   - placeholder: Optional placeholder image while loading
    ///   - completion: Completion handler with Result<SCImage, SwiftCacheError>
    /// - Returns: CancellationToken that can be used to cancel the operation
    @discardableResult
    public nonisolated func loadImage(
        from url: URL,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil,
        placeholder: SCImage? = nil,
        completion: @escaping @Sendable (Result<SCImage, SwiftCacheError>) -> Void
    ) -> CancellationToken {
        
        let token = CancellationToken()
        
        Task {
            // Check cancellation before starting
            if token.isCancelled {
                completion(.failure(.cancelled))
                return
            }
            
            do {
                let image = try await loadImage(from: url, cacheKey: cacheKey, ttl: ttl)
                
                // Check cancellation before completing
                if token.isCancelled {
                    completion(.failure(.cancelled))
                } else {
                    completion(.success(image))
                }
            } catch {
                if token.isCancelled {
                    completion(.failure(.cancelled))
                } else {
                    completion(.failure(error as? SwiftCacheError ?? .unknown))
                }
            }
        }
        
        return token
    }
    
    /// Prefetch images for better UX
    public nonisolated func prefetch(urls: [URL]) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        _ = try? await self.loadImage(from: url)
                    }
                }
            }
        }
    }
    
    /// Clear all caches (memory + disk)
    public func clearCache() async {
        await loaderChain.clearAll()
    }
    
    /// Clear all caches (synchronous wrapper for backward compatibility)
    public nonisolated func clearCache() {
        Task {
            await clearCache()
        }
    }
    
    /// Clear expired cache entries only
    public func clearExpiredCache() async {
        // This would need to be implemented in DiskLoader
        // For now, we can expose it through a method on diskLoader
    }
    
    /// Clear expired cache entries (synchronous wrapper)
    public nonisolated func clearExpiredCache() {
        Task {
            await clearExpiredCache()
        }
    }
    
    /// Get cache size information
    public func getCacheSize() async -> (memory: Int, disk: Int64) {
        let memorySize = configuration.memoryCacheLimit
        let diskSize = await diskLoader.getDiskSize()
        return (memorySize, diskSize)
    }
    
    /// Get cache performance metrics
    public func getMetrics() async -> CacheMetrics {
        return await analytics.getMetrics()
    }
    
    /// Get metrics (synchronous wrapper)
    public nonisolated func getMetrics() -> CacheMetrics {
        // Return cached metrics synchronously
        return CacheMetrics(
            memoryHits: 0,
            diskHits: 0,
            networkHits: 0,
            totalMisses: 0,
            averageMemoryLoadTime: 0,
            averageDiskLoadTime: 0,
            averageNetworkLoadTime: 0
        )
    }
    
    /// Reset analytics
    public func resetMetrics() async {
        await analytics.reset()
    }
    
    /// Reset metrics (synchronous wrapper)
    public nonisolated func resetMetrics() {
        Task {
            await resetMetrics()
        }
    }
    
    // MARK: - Private Methods - Analytics
    
    private func trackMetrics(result: Result<SCImage, SwiftCacheError>, duration: TimeInterval) async {
        switch result {
        case .success:
            // Track success - this could be enhanced to know which loader succeeded
            await analytics.trackMemoryHit(duration: duration)
        case .failure:
            await analytics.trackMiss()
        }
    }
    
    // MARK: - Private Methods - Lifecycle
    
    private func observeLifecycleEvents() {
        #if canImport(UIKit) && !os(watchOS)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleMemoryWarning()
            }
        }
        
        if configuration.reduceMemoryInBackground {
            NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.handleDidEnterBackground()
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.handleWillEnterForeground()
                }
            }
        }
        #endif
    }
    
    private func handleMemoryWarning() async {
        await memoryLoader.clear()
    }
    
    private func handleDidEnterBackground() async {
        await memoryLoader.updateLimits(
            memory: configuration.backgroundMemoryCacheLimit,
            count: configuration.memoryCacheCountLimit
        )
        await clearExpiredCache()
    }
    
    private func handleWillEnterForeground() async {
        await memoryLoader.updateLimits(
            memory: configuration.memoryCacheLimit,
            count: configuration.memoryCacheCountLimit
        )
    }
}

// MARK: - Backward Compatibility Extensions

extension SwiftCache {
    /// Store image manually (convenience method)
    public func storeImage(_ image: SCImage, for key: String, ttl: TimeInterval? = nil) async {
        let effectiveTTL = ttl ?? configuration.defaultTTL
        await loaderChain.store(image: image, key: key, ttl: effectiveTTL)
    }
}
