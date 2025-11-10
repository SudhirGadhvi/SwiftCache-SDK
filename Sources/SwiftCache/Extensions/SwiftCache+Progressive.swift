//
//  SwiftCache+Progressive.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Progressive loading support for SwiftCache
extension SwiftCache {
    
    /// Load image with progressive loading (thumbnail → full image)
    ///
    /// - Parameters:
    ///   - url: The URL of the full-size image
    ///   - thumbnailURL: Optional URL for thumbnail (if nil, generates from full-size)
    ///   - cacheKey: Optional custom cache key
    ///   - ttl: Optional time-to-live
    ///   - onThumbnail: Called when thumbnail is loaded
    ///   - onFullImage: Called when full image is loaded
    /// - Returns: CancellationToken for the operation
    @discardableResult
    public nonisolated func loadImageProgressive(
        from url: URL,
        thumbnailURL: URL? = nil,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil,
        onThumbnail: @escaping @Sendable @MainActor (SCImage) -> Void,
        onFullImage: @escaping @Sendable @MainActor (Result<SCImage, SwiftCacheError>) -> Void
    ) -> CancellationToken {
        
        let token = CancellationToken()
        let key = cacheKey ?? url.absoluteString
        
        Task {
            let config = await configuration
            
            guard config.enableProgressiveLoading else {
                // Progressive loading disabled, just load full image
                do {
                    let image = try await loadImage(from: url, cacheKey: cacheKey, ttl: ttl)
                    await onFullImage(.success(image))
                } catch {
                    await onFullImage(.failure(error as? SwiftCacheError ?? .unknown))
                }
                return
            }
            
            // Check if cancelled
            if token.isCancelled { return }
            
            // Step 1: Try to load thumbnail first
            if let thumbnailURL = thumbnailURL {
                do {
                    let thumbnail = try await loadImage(from: thumbnailURL, cacheKey: "\(key)_thumb", ttl: ttl)
                    await onThumbnail(thumbnail)
                } catch {
                    // Thumbnail failed, continue to full image
                }
                
                // Step 2: Load full image
                if !token.isCancelled {
                    do {
                        let fullImage = try await loadImage(from: url, cacheKey: key, ttl: ttl)
                        await onFullImage(.success(fullImage))
                    } catch {
                        await onFullImage(.failure(error as? SwiftCacheError ?? .unknown))
                    }
                }
            } else {
                // Generate thumbnail from full image
                do {
                    let fullImage = try await loadImage(from: url, cacheKey: key, ttl: ttl)
                    
                    // Generate and show thumbnail first
                    if let thumbnail = await generateThumbnail(from: fullImage) {
                        await onThumbnail(thumbnail)
                    }
                    
                    // Then show full image
                    await onFullImage(.success(fullImage))
                } catch {
                    await onFullImage(.failure(error as? SwiftCacheError ?? .unknown))
                }
            }
        }
        
        return token
    }
    
    // MARK: - Private Helpers
    
    private func generateThumbnail(from image: SCImage) async -> SCImage? {
        #if canImport(UIKit)
        let size = image.size
        let scale = configuration.progressiveThumbnailQuality
        let thumbnailSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        }
        #else
        return nil
        #endif
    }
}

// MARK: - Progressive Loading for UIImageView

#if canImport(UIKit)
@MainActor
extension SwiftCacheImageViewWrapper {
    
    /// Load image with progressive loading
    @discardableResult
    public mutating func setImageProgressive(
        with url: URL?,
        thumbnailURL: URL? = nil,
        placeholder: UIImage? = nil,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil,
        completion: (@MainActor @Sendable (Result<UIImage, SwiftCacheError>) -> Void)? = nil
    ) -> CancellationToken? {
        
        guard let imageView = imageView, let url = url else {
            imageView?.image = placeholder
            completion?(.failure(.invalidURL))
            return nil
        }
        
        // Cancel previous request
        currentToken?.cancel()
        
        // Set placeholder immediately
        imageView.image = placeholder
        
        // Load with progressive loading
        let token = SwiftCache.shared.loadImageProgressive(
            from: url,
            thumbnailURL: thumbnailURL,
            cacheKey: cacheKey,
            ttl: ttl,
            onThumbnail: { [weak imageView] thumbnail in
                guard let imageView = imageView else { return }
                UIView.transition(
                    with: imageView,
                    duration: 0.2,
                    options: .transitionCrossDissolve,
                    animations: {
                        imageView.image = thumbnail
                    }
                )
            },
            onFullImage: { [weak imageView] result in
                guard let imageView = imageView else { return }
                switch result {
                case .success(let image):
                    UIView.transition(
                        with: imageView,
                        duration: 0.3,
                        options: .transitionCrossDissolve,
                        animations: {
                            imageView.image = image
                        }
                    )
                    completion?(.success(image))
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
        )
        
        currentToken = token
        return token
    }
}
#endif
