//
//  UIImageView+SwiftCache.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

#if canImport(UIKit)
import UIKit

// MARK: - SwiftCache UIImageView Wrapper

@MainActor
public struct SwiftCacheImageViewWrapper {
    internal weak var imageView: UIImageView?
    internal var currentToken: CancellationToken?
    
    init(imageView: UIImageView) {
        self.imageView = imageView
    }
    
    /// Load and set image on UIImageView
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - placeholder: Optional placeholder image while loading
    ///   - cacheKey: Optional custom cache key
    ///   - ttl: Optional time-to-live in seconds
    ///   - transition: Animation duration for fade transition (default: 0.2)
    ///   - completion: Optional completion handler
    @discardableResult
    public mutating func setImage(
        with url: URL?,
        placeholder: UIImage? = nil,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil,
        transition: TimeInterval = 0.2,
        completion: (@MainActor @Sendable (Result<UIImage, SwiftCacheError>) -> Void)? = nil
    ) -> CancellationToken? {
        
        guard let imageView = imageView, let url = url else {
            imageView?.image = placeholder
            completion?(.failure(.invalidURL))
            return nil
        }
        
        // Cancel previous request
        currentToken?.cancel()
        
        // Set placeholder immediately (already on MainActor)
        imageView.image = placeholder
        
        // Load image
        let token = SwiftCache.shared.loadImage(from: url, cacheKey: cacheKey, ttl: ttl) { [weak imageView] result in
            // Completion is already called on background, we need to dispatch to main
            Task { @MainActor in
                guard let imageView = imageView else { return }
                
                switch result {
                case .success(let image):
                    if transition > 0 {
                        UIView.transition(
                            with: imageView,
                            duration: transition,
                            options: .transitionCrossDissolve,
                            animations: {
                                imageView.image = image
                            }
                        )
                    } else {
                        imageView.image = image
                    }
                    completion?(.success(image))
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
        }
        
        currentToken = token
        return token
    }
    
    /// Cancel current image load operation
    public func cancelLoad() {
        currentToken?.cancel()
    }
}

// MARK: - UIImageView Extension

extension UIImageView {
    
    /// SwiftCache convenience accessor
    @MainActor
    public var sc: SwiftCacheImageViewWrapper {
        return SwiftCacheImageViewWrapper(imageView: self)
    }
}

// MARK: - Async/Await Support

@available(iOS 15.0, *)
extension SwiftCacheImageViewWrapper {
    
    /// Load and set image with async/await (proper implementation without await MainActor.run)
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - placeholder: Optional placeholder image while loading
    ///   - cacheKey: Optional custom cache key
    ///   - ttl: Optional time-to-live in seconds
    ///   - transition: Animation duration for fade transition (default: 0.2)
    /// - Returns: The loaded image
    /// - Throws: SwiftCacheError if loading fails
    @discardableResult
    public func setImage(
        with url: URL?,
        placeholder: UIImage? = nil,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil,
        transition: TimeInterval = 0.2
    ) async throws -> UIImage {
        
        guard let imageView = imageView, let url = url else {
            // Already on MainActor, no need for await MainActor.run
            imageView?.image = placeholder
            throw SwiftCacheError.invalidURL
        }
        
        // Set placeholder immediately (already on MainActor)
        imageView.image = placeholder
        
        // Load image (this suspends and switches off MainActor)
        let image = try await SwiftCache.shared.loadImage(from: url, cacheKey: cacheKey, ttl: ttl)
        
        // Back on MainActor automatically due to @MainActor annotation
        if transition > 0 {
            UIView.transition(
                with: imageView,
                duration: transition,
                options: .transitionCrossDissolve,
                animations: {
                    imageView.image = image
                }
            )
        } else {
            imageView.image = image
        }
        
        return image
    }
}

#endif
