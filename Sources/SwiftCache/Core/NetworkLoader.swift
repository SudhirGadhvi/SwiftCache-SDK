//
//  NetworkLoader.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Network loader with async/await
public actor NetworkLoader: CacheLoader {
    private let configuration: CacheConfiguration
    private let urlSession: URLSession
    
    public init(configuration: CacheConfiguration) {
        self.configuration = configuration
        
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: configuration.networkCacheMemoryLimit,
            diskCapacity: configuration.networkCacheDiskLimit
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.urlSession = URLSession(configuration: config)
    }
    
    public func load(key: String, url: URL, ttl: TimeInterval) async -> SCImage? {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        
        do {
            let (data, _) = try await urlSession.data(for: request)
            guard let image = SCImage(data: data) else {
                return nil
            }
            
            // Process image (downscale if needed)
            return await processImage(image)
        } catch {
            return nil
        }
    }
    
    public func store(image: SCImage, key: String, ttl: TimeInterval) async {
        // Network loader doesn't store images
    }
    
    public func clear() async {
        urlSession.configuration.urlCache?.removeAllCachedResponses()
    }
    
    // MARK: - Image Processing
    
    private func processImage(_ image: SCImage) async -> SCImage {
        guard let maxDimension = configuration.maxImageDimension else {
            return image
        }
        
        #if canImport(UIKit)
        return await downscaleImageUIKit(image, maxDimension: maxDimension)
        #elseif canImport(AppKit)
        return await downscaleImageAppKit(image, maxDimension: maxDimension)
        #endif
    }
    
    #if canImport(UIKit)
    private func downscaleImageUIKit(_ image: UIImage, maxDimension: CGFloat) async -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else {
            return image
        }
        
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        // Use modern UIGraphicsImageRenderer for better performance
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    #endif
    
    #if canImport(AppKit)
    private func downscaleImageAppKit(_ image: NSImage, maxDimension: CGFloat) async -> NSImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else {
            return image
        }
        
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        // Create a new NSImage with the scaled size
        let scaledImage = NSImage(size: newSize)
        scaledImage.lockFocus()
        
        // Draw the original image scaled down
        let destRect = NSRect(origin: .zero, size: newSize)
        let sourceRect = NSRect(origin: .zero, size: size)
        
        image.draw(in: destRect, from: sourceRect, operation: .copy, fraction: 1.0)
        
        scaledImage.unlockFocus()
        return scaledImage
    }
    #endif
}


