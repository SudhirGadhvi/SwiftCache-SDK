//
//  CancellationToken.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import Foundation

/// A token that can be used to cancel an ongoing image load operation
public final class CancellationToken: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let lock = NSLock()
    private var _isCancelled: Bool = false
    private var task: Task<Void, Never>?
    
    // MARK: - Public API
    
    /// Check if the operation has been cancelled
    public var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isCancelled
    }
    
    /// Cancel the ongoing image load operation
    public func cancel() {
        lock.lock()
        _isCancelled = true
        let taskToCancel = task
        lock.unlock()
        
        taskToCancel?.cancel()
    }
    
    // MARK: - Internal API
    
    internal func setTask(_ task: Task<Void, Never>) {
        lock.lock()
        self.task = task
        lock.unlock()
    }
}
