//
//  CacheAnalytics.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation

/// Cache performance metrics
public struct CacheMetrics: Sendable {
    public let memoryHits: Int
    public let diskHits: Int
    public let networkHits: Int
    public let totalMisses: Int
    public let averageMemoryLoadTime: TimeInterval
    public let averageDiskLoadTime: TimeInterval
    public let averageNetworkLoadTime: TimeInterval
    
    public var totalRequests: Int {
        return memoryHits + diskHits + networkHits + totalMisses
    }
    
    public var hitRate: Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(memoryHits + diskHits + networkHits) / Double(totalRequests)
    }
}

/// Analytics tracking for cache performance using actor for thread-safety
actor CacheAnalytics {
    
    // MARK: - Properties
    
    private var memoryHits = 0
    private var memoryLoadTimes: [TimeInterval] = []
    
    private var diskHits = 0
    private var diskLoadTimes: [TimeInterval] = []
    
    private var networkHits = 0
    private var networkLoadTimes: [TimeInterval] = []
    
    private var misses = 0
    
    // MARK: - Tracking
    
    func trackMemoryHit(duration: TimeInterval) {
        memoryHits += 1
        memoryLoadTimes.append(duration)
    }
    
    func trackDiskHit(duration: TimeInterval) {
        diskHits += 1
        diskLoadTimes.append(duration)
    }
    
    func trackNetworkHit(duration: TimeInterval) {
        networkHits += 1
        networkLoadTimes.append(duration)
    }
    
    func trackMiss() {
        misses += 1
    }
    
    // MARK: - Metrics
    
    func getMetrics() -> CacheMetrics {
        let avgMemoryTime = memoryLoadTimes.isEmpty ? 0 : memoryLoadTimes.reduce(0, +) / TimeInterval(memoryLoadTimes.count)
        let avgDiskTime = diskLoadTimes.isEmpty ? 0 : diskLoadTimes.reduce(0, +) / TimeInterval(diskLoadTimes.count)
        let avgNetworkTime = networkLoadTimes.isEmpty ? 0 : networkLoadTimes.reduce(0, +) / TimeInterval(networkLoadTimes.count)
        
        return CacheMetrics(
            memoryHits: memoryHits,
            diskHits: diskHits,
            networkHits: networkHits,
            totalMisses: misses,
            averageMemoryLoadTime: avgMemoryTime,
            averageDiskLoadTime: avgDiskTime,
            averageNetworkLoadTime: avgNetworkTime
        )
    }
    
    func reset() {
        memoryHits = 0
        memoryLoadTimes.removeAll()
        diskHits = 0
        diskLoadTimes.removeAll()
        networkHits = 0
        networkLoadTimes.removeAll()
        misses = 0
    }
}
