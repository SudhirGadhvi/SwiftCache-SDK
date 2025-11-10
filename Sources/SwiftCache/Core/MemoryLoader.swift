//
//  MemoryLoader.swift
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

/// Memory cache loader using NSCache (thread-safe)
public actor MemoryLoader: CacheLoader {
    private let cache = NSCache<NSString, CacheEntry>()
    private let configuration: CacheConfiguration
    
    public init(configuration: CacheConfiguration) {
        self.configuration = configuration
        Task {
            await setupCache()
        }
    }
    
    private func setupCache() {
        cache.totalCostLimit = configuration.memoryCacheLimit
        cache.countLimit = configuration.memoryCacheCountLimit
        cache.name = "com.swiftcache.memory"
    }
    
    public func load(key: String, url: URL, ttl: TimeInterval) async -> SCImage? {
        // NSCache is thread-safe, but we're still in actor context for consistency
        guard let entry = cache.object(forKey: key as NSString), !entry.isExpired else {
            return nil
        }
        return entry.image
    }
    
    public func store(image: SCImage, key: String, ttl: TimeInterval) async {
        #if canImport(UIKit)
        guard let imageData = image.jpegData(compressionQuality: configuration.diskImageQuality) else { return }
        #elseif canImport(AppKit)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let imageData = bitmapRep.representation(using: .jpeg, properties: [:]) else { return }
        #endif
        
        let entry = CacheEntry(image: image, timestamp: Date(), ttl: ttl, size: imageData.count)
        cache.setObject(entry, forKey: key as NSString, cost: imageData.count)
    }
    
    public func clear() async {
        cache.removeAllObjects()
    }
    
    public func updateLimits(memory: Int, count: Int) {
        cache.totalCostLimit = memory
        cache.countLimit = count
    }
}

