//
//  CacheLoader.swift
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

// MARK: - Strategy Pattern: CacheLoader Protocol

/// Protocol defining a cache loader strategy
/// Users can implement custom loaders for memory, disk, or network
public protocol CacheLoader: Sendable {
    /// Load an image for the given key
    /// - Parameters:
    ///   - key: The cache key
    ///   - url: The original URL (for network loaders)
    ///   - ttl: Time-to-live for the cache entry
    /// - Returns: The loaded image, or nil if not found/failed
    func load(key: String, url: URL, ttl: TimeInterval) async -> SCImage?
    
    /// Store an image
    /// - Parameters:
    ///   - image: The image to store
    ///   - key: The cache key
    ///   - ttl: Time-to-live for the cache entry
    func store(image: SCImage, key: String, ttl: TimeInterval) async
    
    /// Clear all cached data
    func clear() async
}

// MARK: - Chain of Responsibility: CacheLoaderChain

/// Chain of Responsibility pattern for cache loading
/// Tries each loader in sequence (memory → disk → network)
public actor CacheLoaderChain {
    private var loaders: [CacheLoader]
    private let configuration: CacheConfiguration
    
    public init(loaders: [CacheLoader], configuration: CacheConfiguration) {
        self.loaders = loaders
        self.configuration = configuration
    }
    
    /// Load image by trying each loader in the chain
    public func load(key: String, url: URL, ttl: TimeInterval) async -> Result<SCImage, SwiftCacheError> {
        // Try each loader in sequence
        for (index, loader) in loaders.enumerated() {
            if let image = await loader.load(key: key, url: url, ttl: ttl) {
                // Promote to previous layers (e.g., if found on disk, store in memory)
                for previousIndex in 0..<index {
                    await loaders[previousIndex].store(image: image, key: key, ttl: ttl)
                }
                return .success(image)
            }
        }
        
        // All loaders failed
        return .failure(.imageNotFound)
    }
    
    /// Store image in all loaders
    public func store(image: SCImage, key: String, ttl: TimeInterval) async {
        await withTaskGroup(of: Void.self) { group in
            for loader in loaders {
                group.addTask {
                    await loader.store(image: image, key: key, ttl: ttl)
                }
            }
        }
    }
    
    /// Clear all loaders
    public func clearAll() async {
        await withTaskGroup(of: Void.self) { group in
            for loader in loaders {
                group.addTask {
                    await loader.clear()
                }
            }
        }
    }
    
    /// Update loaders (allows custom implementations)
    public func setLoaders(_ newLoaders: [CacheLoader]) {
        self.loaders = newLoaders
    }
}

