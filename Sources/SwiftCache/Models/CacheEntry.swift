//
//  CacheEntry.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
public typealias SCImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias SCImage = NSImage
#endif

/// A cache entry that wraps an image with TTL (time-to-live) support
final class CacheEntry {
    
    // MARK: - Properties
    
    let image: SCImage
    let timestamp: Date
    let ttl: TimeInterval
    let size: Int
    
    // MARK: - Computed Properties
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > ttl
    }
    
    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
    
    // MARK: - Initialization
    
    init(image: SCImage, timestamp: Date = Date(), ttl: TimeInterval, size: Int) {
        self.image = image
        self.timestamp = timestamp
        self.ttl = ttl
        self.size = size
    }
}

