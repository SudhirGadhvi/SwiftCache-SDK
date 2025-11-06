//
//  SwiftCache.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation
import CryptoKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A lightweight, zero-dependency image caching library built on 100% Apple native APIs.
///
/// SwiftCache provides three-tier caching: Memory → Disk → Network
/// with automatic TTL (time-to-live) support and lifecycle-aware memory management.
public final class SwiftCache {
    
    // MARK: - Singleton
    
    public static let shared = SwiftCache()
    
    // MARK: - Properties
    
    public private(set) var configuration = CacheConfiguration()
    private let memoryCache = NSCache<NSString, CacheEntry>()
    private let analytics = CacheAnalytics()
    private let fileManager = FileManager.default
    private let processingQueue = DispatchQueue(label: "com.swiftcache.processing", qos: .utility)
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: configuration.networkCacheMemoryLimit,
            diskCapacity: configuration.networkCacheDiskLimit
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
    
    private lazy var diskCacheDirectory: URL = {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("SwiftCache")
    }()
    
    // MARK: - Initialization
    
    private init() {
        setupMemoryCache()
        createDiskCacheDirectory()
        observeLifecycleEvents()
    }
    
    // MARK: - Configuration
    
    /// Configure SwiftCache with custom settings
    public func configure(_ configurator: (inout CacheConfiguration) -> Void) {
        configurator(&configuration)
        setupMemoryCache()
    }
    
    // MARK: - Public API - Callback-based
    
    /// Load image with three-tier fallback (Memory → Disk → Network)
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - cacheKey: Optional custom cache key (defaults to URL string)
    ///   - ttl: Optional time-to-live in seconds (defaults to configuration.defaultTTL)
    ///   - placeholder: Optional placeholder image while loading
    ///   - completion: Completion handler with Result<SCImage, SwiftCacheError>
    /// - Returns: CancellationToken that can be used to cancel the operation
    @discardableResult
    public func loadImage(
        from url: URL,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil,
        placeholder: SCImage? = nil,
        completion: @escaping (Result<SCImage, SwiftCacheError>) -> Void
    ) -> CancellationToken {
        
        let key = cacheKey ?? url.absoluteString
        let token = CancellationToken()
        let effectiveTTL = ttl ?? configuration.defaultTTL
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 1. Check memory cache first (fastest)
        if let entry = memoryCache.object(forKey: key as NSString), !entry.isExpired {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            if configuration.enableAnalytics {
                analytics.trackMemoryHit(duration: duration)
            }
            completion(.success(entry.image))
            return token
        }
        
        // 2. Check disk cache on background thread
        processingQueue.async { [weak self] in
            guard let self = self, !token.isCancelled else { return }
            
            if let image = self.loadFromDisk(key: key, ttl: effectiveTTL) {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                if self.configuration.enableAnalytics {
                    self.analytics.trackDiskHit(duration: duration)
                }
                
                // Store in memory for next time
                self.storeInMemory(image: image, key: key, ttl: effectiveTTL)
                
                DispatchQueue.main.async {
                    completion(.success(image))
                }
                return
            }
            
            // 3. Download from network
            DispatchQueue.main.async {
                self.downloadImage(
                    from: url,
                    token: token,
                    key: key,
                    ttl: effectiveTTL,
                    startTime: startTime,
                    completion: completion
                )
            }
        }
        
        return token
    }
    
    /// Prefetch images for better UX
    public func prefetch(urls: [URL]) {
        urls.forEach { url in
            loadImage(from: url) { _ in }
        }
    }
    
    /// Clear all caches (memory + disk)
    public func clearCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: diskCacheDirectory)
        createDiskCacheDirectory()
        urlSession.configuration.urlCache?.removeAllCachedResponses()
    }
    
    /// Clear expired cache entries only
    public func clearExpiredCache() {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard let files = try? self.fileManager.contentsOfDirectory(
                at: self.diskCacheDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: []
            ) else { return }
            
            let maxAge = self.configuration.diskCacheMaxAge
            let now = Date()
            
            for fileURL in files {
                if let attributes = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
                   let modDate = attributes.contentModificationDate,
                   now.timeIntervalSince(modDate) > maxAge {
                    try? self.fileManager.removeItem(at: fileURL)
                }
            }
        }
    }
    
    /// Get cache size information
    public func getCacheSize() -> (memory: Int, disk: Int64) {
        let memorySize = memoryCache.totalCostLimit
        let diskSize = calculateDiskSize()
        return (memorySize, diskSize)
    }
    
    /// Get cache performance metrics
    public func getMetrics() -> CacheMetrics {
        return analytics.getMetrics()
    }
    
    /// Reset analytics
    public func resetMetrics() {
        analytics.reset()
    }
    
    // MARK: - Private Methods - Memory Cache
    
    private func setupMemoryCache() {
        memoryCache.totalCostLimit = configuration.memoryCacheLimit
        memoryCache.countLimit = configuration.memoryCacheCountLimit
        memoryCache.name = "com.swiftcache.memory"
    }
    
    private func storeInMemory(image: SCImage, key: String, ttl: TimeInterval) {
        #if canImport(UIKit)
        let imageData = image.jpegData(compressionQuality: configuration.diskImageQuality) ?? Data()
        #elseif canImport(AppKit)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let bitmapRep = NSBitmapImageRep(cgImage: cgImage),
              let imageData = bitmapRep.representation(using: .jpeg, properties: [:]) else { return }
        #endif
        
        let entry = CacheEntry(image: image, timestamp: Date(), ttl: ttl, size: imageData.count)
        memoryCache.setObject(entry, forKey: key as NSString, cost: imageData.count)
    }
    
    // MARK: - Private Methods - Disk Cache
    
    private func createDiskCacheDirectory() {
        try? fileManager.createDirectory(
            at: diskCacheDirectory,
            withIntermediateDirectories: true
        )
    }
    
    private func diskCacheURL(for key: String) -> URL {
        let hash = sha256Hash(of: key)
        return diskCacheDirectory.appendingPathComponent("\(hash).jpg")
    }
    
    private func loadFromDisk(key: String, ttl: TimeInterval) -> SCImage? {
        let fileURL = diskCacheURL(for: key)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let attributes = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
              let modDate = attributes.contentModificationDate else {
            return nil
        }
        
        // Check if expired
        if Date().timeIntervalSince(modDate) > ttl {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = SCImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func storeToDisk(image: SCImage, key: String) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            #if canImport(UIKit)
            guard let data = image.jpegData(compressionQuality: self.configuration.diskImageQuality) else { return }
            #elseif canImport(AppKit)
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
                  let bitmapRep = NSBitmapImageRep(cgImage: cgImage),
                  let data = bitmapRep.representation(using: .jpeg, properties: [:]) else { return }
            #endif
            
            let fileURL = self.diskCacheURL(for: key)
            try? data.write(to: fileURL)
            
            // Cleanup if disk cache is too large
            self.cleanupDiskCacheIfNeeded()
        }
    }
    
    private func calculateDiskSize() -> Int64 {
        var totalSize: Int64 = 0
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: diskCacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: []
        ) else { return 0 }
        
        for fileURL in files {
            if let attributes = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = attributes.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return totalSize
    }
    
    private func cleanupDiskCacheIfNeeded() {
        let currentSize = calculateDiskSize()
        guard currentSize > configuration.diskCacheLimit else { return }
        
        // Perform LRU cleanup
        guard let files = try? fileManager.contentsOfDirectory(
            at: diskCacheDirectory,
            includingPropertiesForKeys: [.contentAccessDateKey, .fileSizeKey],
            options: []
        ) else { return }
        
        // Sort by access date (oldest first)
        let sortedFiles = files.sorted { file1, file2 in
            let date1 = (try? file1.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate) ?? .distantPast
            let date2 = (try? file2.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate) ?? .distantPast
            return date1 < date2
        }
        
        var currentSize = self.calculateDiskSize()
        let targetSize = configuration.diskCacheLimit * 3 / 4 // Clean to 75%
        
        for fileURL in sortedFiles {
            guard currentSize > targetSize else { break }
            
            if let attributes = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = attributes.fileSize {
                try? fileManager.removeItem(at: fileURL)
                currentSize -= Int64(fileSize)
            }
        }
    }
    
    // MARK: - Private Methods - Network
    
    private func downloadImage(
        from url: URL,
        token: CancellationToken,
        key: String,
        ttl: TimeInterval,
        startTime: CFAbsoluteTime,
        completion: @escaping (Result<SCImage, SwiftCacheError>) -> Void
    ) {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if token.isCancelled {
                DispatchQueue.main.async {
                    completion(.failure(.cancelled))
                }
                return
            }
            
            if let error = error {
                if self.configuration.enableAnalytics {
                    self.analytics.trackMiss()
                }
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let data = data, let image = SCImage(data: data) else {
                if self.configuration.enableAnalytics {
                    self.analytics.trackMiss()
                }
                DispatchQueue.main.async {
                    completion(.failure(.invalidImageData))
                }
                return
            }
            
            // Process image if needed (downscale)
            let processedImage = self.processImage(image)
            
            // Store in caches
            self.storeInMemory(image: processedImage, key: key, ttl: ttl)
            self.storeToDisk(image: processedImage, key: key)
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            if self.configuration.enableAnalytics {
                self.analytics.trackNetworkHit(duration: duration)
            }
            
            DispatchQueue.main.async {
                completion(.success(processedImage))
            }
        }
        
        token.setTask(task)
        task.resume()
    }
    
    private func processImage(_ image: SCImage) -> SCImage {
        guard let maxDimension = configuration.maxImageDimension else {
            return image
        }
        
        #if canImport(UIKit)
        let size = image.size
        guard max(size.width, size.height) > maxDimension else {
            return image
        }
        
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
        #else
        return image
        #endif
    }
    
    // MARK: - Private Methods - Lifecycle
    
    private func observeLifecycleEvents() {
        #if canImport(UIKit) && !os(watchOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        if configuration.reduceMemoryInBackground {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
        }
        #endif
    }
    
    @objc private func handleMemoryWarning() {
        memoryCache.removeAllObjects()
    }
    
    @objc private func handleDidEnterBackground() {
        memoryCache.totalCostLimit = configuration.backgroundMemoryCacheLimit
        clearExpiredCache()
    }
    
    @objc private func handleWillEnterForeground() {
        memoryCache.totalCostLimit = configuration.memoryCacheLimit
    }
    
    // MARK: - Utilities
    
    private func sha256Hash(of string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

