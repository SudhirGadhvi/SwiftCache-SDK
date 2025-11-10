//
//  DiskLoader.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation
import CryptoKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Disk cache loader
public actor DiskLoader: CacheLoader {
    private let fileManager = FileManager.default
    private let configuration: CacheConfiguration
    private let cacheDirectory: URL
    
    public init(configuration: CacheConfiguration) {
        self.configuration = configuration
        
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = paths[0].appendingPathComponent("SwiftCache")
        
        Task {
            await createCacheDirectory()
        }
    }
    
    private func createCacheDirectory() async {
        try? fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }
    
    private func cacheURL(for key: String) -> URL {
        let hash = sha256Hash(of: key)
        return cacheDirectory.appendingPathComponent("\(hash).jpg")
    }
    
    private func sha256Hash(of string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    public func load(key: String, url: URL, ttl: TimeInterval) async -> SCImage? {
        let fileURL = cacheURL(for: key)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let attributes = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
              let modDate = attributes.contentModificationDate else {
            return nil
        }
        
        // Check if expired
        if Date().timeIntervalSince(modDate) > ttl {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = SCImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    public func store(image: SCImage, key: String, ttl: TimeInterval) async {
        #if canImport(UIKit)
        guard let data = image.jpegData(compressionQuality: configuration.diskImageQuality) else { return }
        #elseif canImport(AppKit)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmapRep.representation(using: .jpeg, properties: [:]) else { return }
        #endif
        
        let fileURL = cacheURL(for: key)
        try? data.write(to: fileURL)
        
        // Cleanup if disk cache is too large
        await cleanupIfNeeded()
    }
    
    public func clear() async {
        try? fileManager.removeItem(at: cacheDirectory)
        await createCacheDirectory()
    }
    
    private func calculateDiskSize() -> Int64 {
        var totalSize: Int64 = 0
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: []
        ) else { return 0 }
        
        for fileURL in files {
            if let attributes = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = attributes.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return totalSize
    }
    
    private func cleanupIfNeeded() async {
        let currentSize = calculateDiskSize()
        guard currentSize > configuration.diskCacheLimit else { return }
        
        // Perform LRU cleanup
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentAccessDateKey, .fileSizeKey],
            options: []
        ) else { return }
        
        // Sort by access date (oldest first)
        let sortedFiles = files.sorted { file1, file2 in
            let date1 = (try? file1.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate) ?? .distantPast
            let date2 = (try? file2.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate) ?? .distantPast
            return date1 < date2
        }
        
        var sizeToClean = currentSize
        let targetSize = configuration.diskCacheLimit * 3 / 4 // Clean to 75%
        
        for fileURL in sortedFiles {
            guard sizeToClean > targetSize else { break }
            
            if let attributes = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = attributes.fileSize {
                try? fileManager.removeItem(at: fileURL)
                sizeToClean -= Int64(fileSize)
            }
        }
    }
    
    public func getDiskSize() -> Int64 {
        return calculateDiskSize()
    }
}


