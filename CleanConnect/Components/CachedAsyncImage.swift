// CachedAsyncImage.swift
// Image component with memory and disk caching

import SwiftUI
import UIKit

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = url, !isLoading else { return }
        isLoading = true

        // Check cache first
        if let cached = ImageCache.shared.get(for: url) {
            self.image = cached
            isLoading = false
            return
        }

        // Load from network
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    ImageCache.shared.set(uiImage, for: url)
                    await MainActor.run {
                        self.image = uiImage
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// Convenience initializer for common use case
extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?) {
        self.init(
            url: url,
            content: { $0.resizable() },
            placeholder: { ProgressView() }
        )
    }
}

// MARK: - Image Cache

final class ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // Setup memory cache limits
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB

        // Setup disk cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func get(for url: URL) -> UIImage? {
        let nsURL = url as NSURL

        // Check memory cache
        if let cached = memoryCache.object(forKey: nsURL) {
            return cached
        }

        // Check disk cache
        let filePath = cacheFilePath(for: url)
        if let data = try? Data(contentsOf: filePath),
           let image = UIImage(data: data) {
            // Store in memory cache for faster access
            memoryCache.setObject(image, forKey: nsURL)
            return image
        }

        return nil
    }

    func set(_ image: UIImage, for url: URL) {
        let nsURL = url as NSURL

        // Store in memory cache
        memoryCache.setObject(image, forKey: nsURL)

        // Store on disk
        let filePath = cacheFilePath(for: url)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: filePath)
        }
    }

    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    func clearDiskCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func cacheFilePath(for url: URL) -> URL {
        let filename = url.absoluteString.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        return cacheDirectory.appendingPathComponent(filename)
    }
}
