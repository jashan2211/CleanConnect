// StorageService.swift
// Firebase Storage for image uploads

import Foundation
import FirebaseStorage
import UIKit

@MainActor
class StorageService {
    static let shared = StorageService()

    private let storage = Storage.storage()

    private init() {}

    // MARK: - Post Images

    /// Upload a post image (before or after photo)
    /// - Parameters:
    ///   - imageData: The image data to upload
    ///   - postId: The post ID for organizing storage
    ///   - type: "before" or "after"
    /// - Returns: The download URL string
    func uploadPostImage(_ imageData: Data, postId: String, type: String) async throws -> String {
        let path = "posts/\(postId)/\(type)_\(UUID().uuidString).jpg"
        let ref = storage.reference().child(path)

        // Compress image if needed
        let compressedData = compressImage(imageData, maxSizeKB: 500)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(compressedData, metadata: metadata)
        let url = try await ref.downloadURL()

        return url.absoluteString
    }

    /// Upload user profile photo
    func uploadProfilePhoto(_ imageData: Data, userId: String) async throws -> String {
        let path = "users/\(userId)/profile_\(UUID().uuidString).jpg"
        let ref = storage.reference().child(path)

        let compressedData = compressImage(imageData, maxSizeKB: 200)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(compressedData, metadata: metadata)
        let url = try await ref.downloadURL()

        return url.absoluteString
    }

    /// Upload event/gathering image
    func uploadEventImage(_ imageData: Data, eventId: String) async throws -> String {
        let path = "gatherings/\(eventId)/cover_\(UUID().uuidString).jpg"
        let ref = storage.reference().child(path)

        let compressedData = compressImage(imageData, maxSizeKB: 500)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(compressedData, metadata: metadata)
        let url = try await ref.downloadURL()

        return url.absoluteString
    }

    // MARK: - Delete

    func deleteImage(at url: String) async throws {
        guard let storageUrl = URL(string: url),
              storageUrl.host?.contains("firebasestorage") == true else {
            return // Not a Firebase Storage URL
        }

        let ref = storage.reference(forURL: url)
        try await ref.delete()
    }

    // MARK: - Helpers

    private func compressImage(_ data: Data, maxSizeKB: Int) -> Data {
        guard let image = UIImage(data: data) else { return data }

        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 0.8

        var compressedData = image.jpegData(compressionQuality: compression) ?? data

        // Reduce quality until under max size
        while compressedData.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            compressedData = image.jpegData(compressionQuality: compression) ?? compressedData
        }

        // If still too large, resize the image
        if compressedData.count > maxBytes {
            let scale = sqrt(Double(maxBytes) / Double(compressedData.count))
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )

            UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            compressedData = resizedImage?.jpegData(compressionQuality: 0.8) ?? compressedData
        }

        return compressedData
    }
}
