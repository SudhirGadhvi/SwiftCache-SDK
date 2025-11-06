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

public struct SwiftCacheImageViewWrapper {
    private weak var imageView: UIImageView?
    private var currentToken: CancellationToken?
    
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
        
        // Load image
        let token = SwiftCache.shared.loadImage(from: url, cacheKey: cacheKey, ttl: ttl) { [weak imageView] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    if transition > 0 {
                        UIView.transition(
                            with: imageView ?? UIView(),
                            duration: transition,
                            options: .transitionCrossDissolve,
                            animations: {
                                imageView?.image = image
                            }
                        )
                    } else {
                        imageView?.image = image
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
    public var sc: SwiftCacheImageViewWrapper {
        return SwiftCacheImageViewWrapper(imageView: self)
    }
}

// MARK: - Async/Await Support

@available(iOS 15.0, *)
extension SwiftCacheImageViewWrapper {
    
    /// Load and set image with async/await
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
            imageView?.image = placeholder
            throw SwiftCacheError.invalidURL
        }
        
        // Set placeholder immediately
        await MainActor.run {
            imageView.image = placeholder
        }
        
        // Load image
        let image = try await SwiftCache.shared.loadImage(from: url, cacheKey: cacheKey, ttl: ttl)
        
        // Set image with transition
        await MainActor.run {
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
        }
        
        return image
    }
}

#endif

