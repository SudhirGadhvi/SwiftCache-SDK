//
//  CancellationToken.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation

/// A token that can be used to cancel an ongoing image load operation
public final class CancellationToken {
    
    // MARK: - Properties
    
    private(set) var isCancelled: Bool = false
    private var task: URLSessionDataTask?
    
    // MARK: - Internal API
    
    internal func setTask(_ task: URLSessionDataTask) {
        self.task = task
    }
    
    // MARK: - Public API
    
    /// Cancel the ongoing image load operation
    public func cancel() {
        isCancelled = true
        task?.cancel()
    }
}

