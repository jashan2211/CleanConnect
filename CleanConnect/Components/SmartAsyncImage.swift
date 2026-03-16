// SmartAsyncImage.swift
// Handles both local file paths and remote URLs for images

import SwiftUI
import UIKit

/// A smart image view that handles both local file paths and remote URLs
/// Use this instead of AsyncImage when the URL might be a local file path
struct SmartAsyncImage<Content: View, Placeholder: View>: View {
    let urlString: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    init(
        url urlString: String?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        if let urlString = urlString, !urlString.isEmpty {
            if urlString.hasPrefix("/") {
                // Local file path
                LocalFileImage(path: urlString, content: content, placeholder: placeholder)
            } else if urlString.hasPrefix("file://") {
                // File URL
                let path = urlString.replacingOccurrences(of: "file://", with: "")
                LocalFileImage(path: path, content: content, placeholder: placeholder)
            } else if let url = URL(string: urlString) {
                // Remote URL
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        content(image)
                    case .failure(_):
                        placeholder()
                    case .empty:
                        placeholder()
                    @unknown default:
                        placeholder()
                    }
                }
            } else {
                placeholder()
            }
        } else {
            placeholder()
        }
    }
}

// Helper for local file images
private struct LocalFileImage<Content: View, Placeholder: View>: View {
    let path: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    var body: some View {
        if let uiImage = UIImage(contentsOfFile: path) {
            content(Image(uiImage: uiImage))
        } else {
            placeholder()
        }
    }
}

// Convenience initializer with default placeholder
extension SmartAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url urlString: String?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = { ProgressView() }
    }
}

// Simple version that just shows the image
struct SmartImage: View {
    let urlString: String?
    var contentMode: ContentMode = .fill

    var body: some View {
        SmartAsyncImage(url: urlString) { image in
            image
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
        }
    }
}

#Preview {
    VStack {
        SmartAsyncImage(url: "https://example.com/image.jpg") { image in
            image.resizable().scaledToFit()
        } placeholder: {
            ProgressView()
        }
        .frame(height: 200)

        SmartImage(urlString: nil)
            .frame(height: 200)
    }
}
