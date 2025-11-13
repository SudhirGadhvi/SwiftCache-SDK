//
//  CachedImage.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI

/// A SwiftUI view that displays a cached image with modern SwiftUI patterns
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CachedImage<Placeholder: View>: View {
    
    private let url: URL?
    private let cacheKey: String?
    private let ttl: TimeInterval?
    private let placeholder: Placeholder
    
    @State private var image: SCImage?
    @State private var isLoading = false
    
    public init(
        url: URL?,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.url = url
        self.cacheKey = cacheKey
        self.ttl = ttl
        self.placeholder = placeholder()
    }
    
    public var body: some View {
        Group {
            if let image = image {
                #if canImport(UIKit)
                Image(uiImage: image)
                    .resizable()
                #elseif canImport(AppKit)
                Image(nsImage: image)
                    .resizable()
                #endif
            } else {
                placeholder
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else { return }
        
        isLoading = true
        
        do {
            let loadedImage = try await SwiftCache.shared.loadImage(
                from: url,
                cacheKey: cacheKey,
                ttl: ttl
            )
            
            // Check for cancellation before updating state
            guard !Task.isCancelled else { return }
            
            // Already on MainActor due to @State access
            withAnimation {
                image = loadedImage
                isLoading = false
            }
        } catch {
            // Check for cancellation
            guard !Task.isCancelled else { return }
            
            isLoading = false
        }
    }
}

// MARK: - Convenience Initializers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CachedImage where Placeholder == EmptyView {
    public init(url: URL?, cacheKey: String? = nil, ttl: TimeInterval? = nil) {
        self.init(url: url, cacheKey: cacheKey, ttl: ttl) {
            EmptyView()
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CachedImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    public init(url: URL?, cacheKey: String? = nil, ttl: TimeInterval? = nil, showProgress: Bool = true) {
        self.init(url: url, cacheKey: cacheKey, ttl: ttl) {
            ProgressView()
        }
    }
}

#endif
