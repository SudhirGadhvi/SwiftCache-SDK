//
//  SwiftCacheTests.swift
//  SwiftCacheTests
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import XCTest
@testable import SwiftCache

final class SwiftCacheTests: XCTestCase {
    
    var sut: SwiftCache!
    
    override func setUp() {
        super.setUp()
        sut = SwiftCache.shared
        sut.clearCache()
    }
    
    override func tearDown() {
        sut.clearCache()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testDefaultConfiguration() {
        XCTAssertEqual(sut.configuration.memoryCacheLimit, 50 * 1024 * 1024)
        XCTAssertEqual(sut.configuration.memoryCacheCountLimit, 100)
        XCTAssertEqual(sut.configuration.defaultTTL, 24 * 60 * 60)
    }
    
    func testCustomConfiguration() {
        sut.configure { config in
            config.memoryCacheLimit = 100 * 1024 * 1024
            config.defaultTTL = 3600
        }
        
        XCTAssertEqual(sut.configuration.memoryCacheLimit, 100 * 1024 * 1024)
        XCTAssertEqual(sut.configuration.defaultTTL, 3600)
    }
    
    // MARK: - Cache Tests
    
    func testLoadImageSuccess() {
        let expectation = XCTestExpectation(description: "Load image")
        let url = URL(string: "https://via.placeholder.com/150")!
        
        sut.loadImage(from: url, placeholder: nil) { result in
            switch result {
            case .success(let image):
                XCTAssertNotNil(image)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to load image: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testCancellation() {
        let url = URL(string: "https://via.placeholder.com/1500")!
        
        let token = sut.loadImage(from: url, placeholder: nil) { result in
            XCTFail("Should not complete after cancellation")
        }
        
        token.cancel()
        XCTAssertTrue(token.isCancelled)
    }
    
    func testClearCache() {
        sut.clearCache()
        let (_, diskSize) = sut.getCacheSize()
        XCTAssertEqual(diskSize, 0)
    }
    
    // MARK: - Analytics Tests
    
    func testAnalytics() {
        sut.configure { config in
            config.enableAnalytics = true
        }
        
        let expectation = XCTestExpectation(description: "Analytics tracking")
        let url = URL(string: "https://via.placeholder.com/150")!
        
        sut.loadImage(from: url, placeholder: nil) { _ in
            let metrics = self.sut.getMetrics()
            XCTAssertGreaterThan(metrics.totalRequests, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}
