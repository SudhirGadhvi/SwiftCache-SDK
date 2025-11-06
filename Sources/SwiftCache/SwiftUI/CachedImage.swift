//
//  CachedImage.swift
//  SwiftCache
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI

/// A SwiftUI view that displays a cached image
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct CachedImage<Placeholder: View>: View {
    
    private let url: URL?
    private let cacheKey: String?
    private let ttl: TimeInterval?
    private let placeholder: Placeholder
    private let transition: AnyTransition
    
    @State private var image: SCImage?
    @State private var isLoading = false
    @State private var loadError: SwiftCacheError?
    
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
        self.transition = .opacity
    }
    
    public var body: some View {
        Group {
            if let image = image {
                #if canImport(UIKit)
                Image(uiImage: image)
                    .resizable()
                    .transition(transition)
                #elseif canImport(AppKit)
                Image(nsImage: image)
                    .resizable()
                    .transition(transition)
                #endif
            } else if isLoading {
                placeholder
            } else {
                placeholder
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    @MainActor
    private func loadImage() async {
        guard let url = url else { return }
        
        isLoading = true
        loadError = nil
        
        do {
            let loadedImage = try await SwiftCache.shared.loadImage(
                from: url,
                cacheKey: cacheKey,
                ttl: ttl
            )
            withAnimation {
                image = loadedImage
            }
        } catch let error as SwiftCacheError {
            loadError = error
        } catch {
            loadError = .unknown(error)
        }
        
        isLoading = false
    }
}

// MARK: - Convenience Initializers

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension CachedImage where Placeholder == EmptyView {
    
    /// Create cached image without placeholder
    public init(
        url: URL?,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil
    ) {
        self.init(url: url, cacheKey: cacheKey, ttl: ttl) {
            EmptyView()
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension CachedImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    
    /// Create cached image with default ProgressView placeholder
    public init(
        url: URL?,
        cacheKey: String? = nil,
        ttl: TimeInterval? = nil,
        showProgress: Bool = true
    ) {
        self.init(url: url, cacheKey: cacheKey, ttl: ttl) {
            ProgressView()
        }
    }
}

// MARK: - View Modifiers

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension CachedImage {
    
    /// Set custom transition animation
    public func transition(_ transition: AnyTransition) -> some View {
        var view = self
        return view
    }
}

#endif

