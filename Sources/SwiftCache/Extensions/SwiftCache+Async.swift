//
//  SwiftCache+Async.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SwiftCache {
    
    /// Load image with async/await support
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - cacheKey: Optional custom cache key
    ///   - ttl: Optional time-to-live in seconds
    /// - Returns: The loaded image
    /// - Throws: SwiftCacheError if loading fails
    public func loadImage(
        from url: URL,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil
    ) async throws -> SCImage {
        return try await withCheckedThrowingContinuation { continuation in
            loadImage(from: url, cacheKey: cacheKey, ttl: ttl) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Load image with async/await and cancellation support
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - cacheKey: Optional custom cache key
    ///   - ttl: Optional time-to-live in seconds
    /// - Returns: The loaded image
    /// - Throws: SwiftCacheError if loading fails or is cancelled
    public func loadImage(
        from url: URL,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil
    ) async throws -> SCImage {
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let token = loadImage(from: url, cacheKey: cacheKey, ttl: ttl) { result in
                    continuation.resume(with: result)
                }
                
                // Store token for cancellation
                Task { [token] in
                    for await _ in NotificationCenter.default.notifications(named: .init("TaskCancellation")) {
                        token.cancel()
                    }
                }
            }
        } onCancel: {
            // Cancellation handled via token
        }
    }
}

