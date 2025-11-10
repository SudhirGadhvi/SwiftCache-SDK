//
//  SwiftCacheError.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation

/// Errors that can occur during image caching operations
public enum SwiftCacheError: Error, LocalizedError, Sendable, Equatable {
    
    case invalidURL
    case networkError(Error)
    case invalidImageData
    case diskWriteError(Error)
    case diskReadError(Error)
    case cancelled
    case imageNotFound
    case unknown
    
    // MARK: - Equatable
    
    public static func == (lhs: SwiftCacheError, rhs: SwiftCacheError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidImageData, .invalidImageData),
             (.cancelled, .cancelled),
             (.imageNotFound, .imageNotFound),
             (.unknown, .unknown):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.diskWriteError(let lhsError), .diskWriteError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.diskReadError(let lhsError), .diskReadError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
    
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
        case .imageNotFound:
            return "Image not found in any cache layer"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

