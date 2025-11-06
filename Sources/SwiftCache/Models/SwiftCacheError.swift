//
//  SwiftCacheError.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation

/// Errors that can occur during image caching operations
public enum SwiftCacheError: Error, LocalizedError {
    
    case invalidURL
    case networkError(Error)
    case invalidImageData
    case diskWriteError(Error)
    case diskReadError(Error)
    case cancelled
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidImageData:
            return "The downloaded data is not a valid image"
        case .diskWriteError(let error):
            return "Failed to write image to disk: \(error.localizedDescription)"
        case .diskReadError(let error):
            return "Failed to read image from disk: \(error.localizedDescription)"
        case .cancelled:
            return "The operation was cancelled"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

