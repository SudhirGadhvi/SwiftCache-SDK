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
    public func loadImageProgressive(
        from url: URL,
        thumbnailURL: URL? = nil,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil,
        onThumbnail: @escaping (SCImage) -> Void,
        onFullImage: @escaping (Result<SCImage, SwiftCacheError>) -> Void
    ) -> CancellationToken {
        
        guard configuration.enableProgressiveLoading else {
            // Progressive loading disabled, just load full image
            return loadImage(from: url, cacheKey: cacheKey, ttl: ttl, completion: onFullImage)
        }
        
        let token = CancellationToken()
        let key = cacheKey ?? url.absoluteString
        
        // Step 1: Try to load thumbnail first
        if let thumbnailURL = thumbnailURL {
            loadImage(from: thumbnailURL, cacheKey: "\(key)_thumb", ttl: ttl) { result in
                if case .success(let thumbnail) = result {
                    onThumbnail(thumbnail)
                }
                
                // Step 2: Load full image regardless of thumbnail result
                if !token.isCancelled {
                    _ = self.loadImage(from: url, cacheKey: key, ttl: ttl, completion: onFullImage)
                }
            }
        } else {
            // Generate thumbnail from full image
            loadImage(from: url, cacheKey: key, ttl: ttl) { result in
                switch result {
                case .success(let fullImage):
                    // Generate and show thumbnail first
                    if let thumbnail = self.generateThumbnail(from: fullImage) {
                        onThumbnail(thumbnail)
                    }
                    // Then show full image
                    onFullImage(.success(fullImage))
                    
                case .failure(let error):
                    onFullImage(.failure(error))
                }
            }
        }
        
        return token
    }
    
    // MARK: - Private Helpers
    
    private func generateThumbnail(from image: SCImage) -> SCImage? {
        #if canImport(UIKit)
        let size = image.size
        let scale = configuration.progressiveThumbnailQuality
        let thumbnailSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        return UIGraphicsGetImageFromCurrentImageContext()
        #else
        return nil
        #endif
    }
}

// MARK: - Progressive Loading for UIImageView

#if canImport(UIKit)
extension SwiftCacheImageViewWrapper {
    
    /// Load image with progressive loading
    @discardableResult
    public mutating func setImageProgressive(
        with url: URL?,
        thumbnailURL: URL? = nil,
        placeholder: UIImage? = nil,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil,
        completion: ((Result<UIImage, SwiftCacheError>) -> Void)? = nil
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
                DispatchQueue.main.async {
                    UIView.transition(
                        with: imageView ?? UIView(),
                        duration: 0.2,
                        options: .transitionCrossDissolve,
                        animations: {
                            imageView?.image = thumbnail
                        }
                    )
                }
            },
            onFullImage: { [weak imageView] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let image):
                        UIView.transition(
                            with: imageView ?? UIView(),
                            duration: 0.3,
                            options: .transitionCrossDissolve,
                            animations: {
                                imageView?.image = image
                            }
                        )
                        completion?(.success(image))
                        
                    case .failure(let error):
                        completion?(.failure(error))
                    }
                }
            }
        )
        
        currentToken = token
        return token
    }
}
#endif

