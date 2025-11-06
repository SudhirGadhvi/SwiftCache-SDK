//
//  CacheConfiguration.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation

/// Configuration options for SwiftCache
public struct CacheConfiguration {
    
    // MARK: - Memory Cache Settings
    
    /// Maximum memory cache size in bytes (default: 50MB)
    public var memoryCacheLimit: Int = 50 * 1024 * 1024
    
    /// Maximum number of images to store in memory (default: 100)
    public var memoryCacheCountLimit: Int = 100
    
    // MARK: - Disk Cache Settings
    
    /// Maximum disk cache size in bytes (default: 500MB)
    public var diskCacheLimit: Int64 = 500 * 1024 * 1024
    
    /// Maximum age for disk cache entries in seconds (default: 30 days)
    public var diskCacheMaxAge: TimeInterval = 30 * 24 * 60 * 60
    
    // MARK: - Network Cache Settings
    
    /// Network cache memory capacity in bytes (default: 50MB)
    public var networkCacheMemoryLimit: Int = 50 * 1024 * 1024
    
    /// Network cache disk capacity in bytes (default: 200MB)
    public var networkCacheDiskLimit: Int = 200 * 1024 * 1024
    
    // MARK: - TTL Settings
    
    /// Default time-to-live for cached images in seconds (default: 24 hours)
    public var defaultTTL: TimeInterval = 24 * 60 * 60
    
    // MARK: - Progressive Loading Settings
    
    /// Enable progressive loading (show thumbnail first, then full image)
    public var enableProgressiveLoading: Bool = true
    
    /// Thumbnail quality for progressive loading (0.0 - 1.0, default: 0.3)
    public var progressiveThumbnailQuality: CGFloat = 0.3
    
    // MARK: - Analytics Settings
    
    /// Enable cache performance analytics
    public var enableAnalytics: Bool = false
    
    // MARK: - Lifecycle Settings
    
    /// Automatically reduce memory cache when app enters background
    public var reduceMemoryInBackground: Bool = true
    
    /// Memory cache limit when app is in background (default: 20MB)
    public var backgroundMemoryCacheLimit: Int = 20 * 1024 * 1024
    
    // MARK: - Image Processing Settings
    
    /// Image compression quality for disk storage (0.0 - 1.0, default: 0.8)
    public var diskImageQuality: CGFloat = 0.8
    
    /// Downscale large images to this maximum dimension (default: nil = no downscale)
    public var maxImageDimension: CGFloat? = nil
    
    // MARK: - Initialization
    
    public init() {}
}

