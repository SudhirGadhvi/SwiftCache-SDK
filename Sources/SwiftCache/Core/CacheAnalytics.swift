//
//  CacheAnalytics.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation

/// Cache performance metrics
public struct CacheMetrics {
    public let memoryHits: Int
    public let diskHits: Int
    public let networkHits: Int
    public let misses: Int
    public let totalRequests: Int
    public let averageLoadTime: TimeInterval
    public let cacheHitRate: Double
    
    public var hitRate: Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(memoryHits + diskHits + networkHits) / Double(totalRequests)
    }
}

/// Analytics tracking for cache performance
final class CacheAnalytics {
    
    // MARK: - Properties
    
    private var memoryHits = 0
    private var diskHits = 0
    private var networkHits = 0
    private var misses = 0
    private var totalRequests = 0
    private var totalLoadTime: TimeInterval = 0
    private let queue = DispatchQueue(label: "com.swiftcache.analytics")
    
    // MARK: - Tracking
    
    func trackMemoryHit(duration: TimeInterval) {
        queue.async {
            self.memoryHits += 1
            self.totalRequests += 1
            self.totalLoadTime += duration
        }
    }
    
    func trackDiskHit(duration: TimeInterval) {
        queue.async {
            self.diskHits += 1
            self.totalRequests += 1
            self.totalLoadTime += duration
        }
    }
    
    func trackNetworkHit(duration: TimeInterval) {
        queue.async {
            self.networkHits += 1
            self.totalRequests += 1
            self.totalLoadTime += duration
        }
    }
    
    func trackMiss() {
        queue.async {
            self.misses += 1
            self.totalRequests += 1
        }
    }
    
    // MARK: - Metrics
    
    func getMetrics() -> CacheMetrics {
        queue.sync {
            let avgLoadTime = totalRequests > 0 ? totalLoadTime / TimeInterval(totalRequests) : 0
            let hitRate = totalRequests > 0 ? Double(memoryHits + diskHits + networkHits) / Double(totalRequests) : 0
            
            return CacheMetrics(
                memoryHits: memoryHits,
                diskHits: diskHits,
                networkHits: networkHits,
                misses: misses,
                totalRequests: totalRequests,
                averageLoadTime: avgLoadTime,
                cacheHitRate: hitRate
            )
        }
    }
    
    func reset() {
        queue.async {
            self.memoryHits = 0
            self.diskHits = 0
            self.networkHits = 0
            self.misses = 0
            self.totalRequests = 0
            self.totalLoadTime = 0
        }
    }
}

