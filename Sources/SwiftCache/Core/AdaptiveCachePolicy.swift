//
//  AdaptiveCachePolicy.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 16/02/2026.
//

import Foundation

/// Runtime telemetry used by adaptive policy engines to recommend cache settings.
public struct CachePolicyTelemetry: Sendable {
    public let totalRequests: Int
    public let memoryHits: Int
    public let diskHits: Int
    public let networkHits: Int
    public let totalMisses: Int
    public let averageLoadTime: TimeInterval
    public let windowDuration: TimeInterval

    public init(
        totalRequests: Int,
        memoryHits: Int,
        diskHits: Int,
        networkHits: Int,
        totalMisses: Int,
        averageLoadTime: TimeInterval,
        windowDuration: TimeInterval
    ) {
        self.totalRequests = totalRequests
        self.memoryHits = memoryHits
        self.diskHits = diskHits
        self.networkHits = networkHits
        self.totalMisses = totalMisses
        self.averageLoadTime = averageLoadTime
        self.windowDuration = windowDuration
    }

    public var hitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(memoryHits + diskHits + networkHits) / Double(totalRequests)
    }

    /// Local cache layers only (memory + disk), excluding network.
    public var cacheHitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(memoryHits + diskHits) / Double(totalRequests)
    }

    public var memoryHitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(memoryHits) / Double(totalRequests)
    }

    public var networkHitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(networkHits) / Double(totalRequests)
    }

    public var missRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(totalMisses) / Double(totalRequests)
    }
}

/// Strategy protocol for adaptive cache policy engines.
public protocol AdaptiveCachePolicyEngine: Sendable {
    /// - Returns: Recommended configuration update, or `nil` to keep existing configuration.
    func recommendConfiguration(
        current configuration: CacheConfiguration,
        telemetry: CachePolicyTelemetry
    ) async -> CacheConfiguration?
}

/// Default adaptive engine tuned for caching efficiency using deterministic local heuristics.
public actor HeuristicAdaptiveCachePolicyEngine: AdaptiveCachePolicyEngine {
    public init() {}

    public func recommendConfiguration(
        current configuration: CacheConfiguration,
        telemetry: CachePolicyTelemetry
    ) async -> CacheConfiguration? {
        guard telemetry.totalRequests > 0 else { return nil }

        var updated = configuration
        var changed = false

        // If local cache hit-rate is low and network dependence is high, expand TTL + cache capacity.
        if telemetry.cacheHitRate < 0.45 && telemetry.networkHitRate > 0.35 {
            let newTTL = min(
                configuration.adaptivePolicyMaxTTL,
                max(configuration.adaptivePolicyMinTTL, configuration.defaultTTL * 1.25)
            )
            if newTTL != updated.defaultTTL {
                updated.defaultTTL = newTTL
                changed = true
            }

            let expandedMemory = min(Int(Double(configuration.memoryCacheLimit) * 1.20), 512 * 1024 * 1024)
            if expandedMemory != updated.memoryCacheLimit {
                updated.memoryCacheLimit = expandedMemory
                changed = true
            }

            let expandedDisk = min(Int64(Double(configuration.diskCacheLimit) * 1.15), 5 * 1024 * 1024 * 1024)
            if expandedDisk != updated.diskCacheLimit {
                updated.diskCacheLimit = expandedDisk
                changed = true
            }
        }

        // If cache is already very effective and fast, scale memory cache down slightly.
        if telemetry.cacheHitRate > 0.90 && telemetry.memoryHitRate > 0.70 && telemetry.averageLoadTime < 0.02 {
            let reducedMemory = max(Int(Double(configuration.memoryCacheLimit) * 0.90), 20 * 1024 * 1024)
            if reducedMemory != updated.memoryCacheLimit {
                updated.memoryCacheLimit = reducedMemory
                changed = true
            }
        }

        // If misses spike, reduce TTL to avoid keeping stale content too long.
        if telemetry.missRate > 0.50 {
            let loweredTTL = max(configuration.adaptivePolicyMinTTL, configuration.defaultTTL * 0.85)
            if loweredTTL != updated.defaultTTL {
                updated.defaultTTL = loweredTTL
                changed = true
            }
        }

        return changed ? updated : nil
    }
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
public actor FoundationModelsAdaptiveCachePolicyEngine: AdaptiveCachePolicyEngine {
    private let model = SystemLanguageModel.default

    public init() {}

    public func recommendConfiguration(
        current configuration: CacheConfiguration,
        telemetry: CachePolicyTelemetry
    ) async -> CacheConfiguration? {
        guard model.availability == .available else { return nil }
        guard telemetry.totalRequests > 0 else { return nil }

        let instructions = """
        You optimize an image cache policy.
        Return conservative updates only.
        Respect these hard limits:
        - defaultTTLSeconds in [\(Int(configuration.adaptivePolicyMinTTL)), \(Int(configuration.adaptivePolicyMaxTTL))]
        - memoryCacheLimitBytes in [20971520, 536870912]
        - diskCacheLimitBytes in [104857600, 5368709120]
        """

        let prompt = """
        Current configuration:
        - defaultTTLSeconds: \(Int(configuration.defaultTTL))
        - memoryCacheLimitBytes: \(configuration.memoryCacheLimit)
        - diskCacheLimitBytes: \(configuration.diskCacheLimit)

        Telemetry window:
        - totalRequests: \(telemetry.totalRequests)
        - memoryHits: \(telemetry.memoryHits)
        - diskHits: \(telemetry.diskHits)
        - networkHits: \(telemetry.networkHits)
        - misses: \(telemetry.totalMisses)
        - averageLoadTimeSeconds: \(telemetry.averageLoadTime)
        - cacheHitRate: \(telemetry.cacheHitRate)
        - missRate: \(telemetry.missRate)

        Recommend updated cache policy values.
        """

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt, generating: FoundationPolicyDecision.self)
            let decision = response.content

            var updated = configuration
            updated.defaultTTL = min(
                configuration.adaptivePolicyMaxTTL,
                max(configuration.adaptivePolicyMinTTL, TimeInterval(decision.defaultTTLSeconds))
            )
            updated.memoryCacheLimit = max(20 * 1024 * 1024, min(decision.memoryCacheLimitBytes, 512 * 1024 * 1024))
            updated.diskCacheLimit = max(
                100 * 1024 * 1024,
                min(Int64(decision.diskCacheLimitBytes), 5 * 1024 * 1024 * 1024)
            )

            let changed = updated.defaultTTL != configuration.defaultTTL ||
                updated.memoryCacheLimit != configuration.memoryCacheLimit ||
                updated.diskCacheLimit != configuration.diskCacheLimit

            return changed ? updated : nil
        } catch {
            return nil
        }
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
@Generable
private struct FoundationPolicyDecision {
    @Guide(description: "Default cache TTL in seconds")
    var defaultTTLSeconds: Int

    @Guide(description: "Memory cache limit in bytes")
    var memoryCacheLimitBytes: Int

    @Guide(description: "Disk cache limit in bytes")
    var diskCacheLimitBytes: Int
}
#endif
