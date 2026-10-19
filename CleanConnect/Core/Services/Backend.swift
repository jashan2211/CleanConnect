import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit

enum DB {
    static var store: Firestore { Firestore.firestore() }
    static var spots: CollectionReference { store.collection("spots") }
    static var drives: CollectionReference { store.collection("drives") }
    static var profiles: CollectionReference { store.collection("profiles") }
    static var userPrivate: CollectionReference { store.collection("userPrivate") }
    static var flags: CollectionReference { store.collection("flags") }
    static var stats: CollectionReference { store.collection("stats") }
    static var cityStats: CollectionReference { store.collection("cityStats") }
}

enum BackendError: LocalizedError {
    case notSignedIn
    case uploadFailed
    case message(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn: String(localized: "Please sign in first.")
        case .uploadFailed: String(localized: "Couldn't upload the photo. Check your connection and try again.")
        case .message(let text): text
        }
    }
}

extension Query {
    /// Live results as an async stream; the listener is removed when the consuming task ends.
    func stream<T>(_ map: @escaping (Doc) -> T?) -> AsyncStream<[T]> {
        AsyncStream { continuation in
            let registration = addSnapshotListener { snapshot, error in
                if let error { print("Firestore listen error:", error.localizedDescription) }
                guard let snapshot else { return }
                continuation.yield(snapshot.documents.compactMap { map(Doc($0)) })
            }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func fetch<T>(_ map: (Doc) -> T?) async throws -> [T] {
        try await getDocuments().documents.compactMap { map(Doc($0)) }
    }
}

extension DocumentReference {
    func stream<T>(_ map: @escaping (Doc) -> T?) -> AsyncStream<T?> {
        AsyncStream { continuation in
            let registration = addSnapshotListener { snapshot, error in
                if let error { print("Firestore doc listen error:", error.localizedDescription) }
                guard let snapshot else { return }
                continuation.yield(snapshot.exists ? map(Doc(snapshot)) : nil)
            }
            continuation.onTermination = { _ in registration.remove() }
        }
    }
}

// MARK: - Media

enum Media {
    /// Uploads a JPEG to Storage and returns its download URL.
    static func upload(_ image: UIImage, path: String) async throws -> String {
        guard let data = image.uploadJPEG() else { throw BackendError.uploadFailed }
        let ref = Storage.storage().reference(withPath: path)
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        meta.cacheControl = "public, max-age=31536000"
        do {
            _ = try await ref.putDataAsync(data, metadata: meta)
            let url = try await ref.downloadURL().absoluteString
            await ImagePipeline.shared.store(image.resized(maxDimension: 1600), for: url)
            return url
        } catch {
            throw BackendError.uploadFailed
        }
    }

    static func upload(_ images: [UIImage], folder: String, prefix: String) async throws -> [String] {
        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let name = "\(prefix)_\(index)_\(Int(Date().timeIntervalSince1970)).jpg"
                    return (index, try await upload(image, path: "\(folder)/\(name)"))
                }
            }
            var urls = [(Int, String)]()
            for try await pair in group { urls.append(pair) }
            return urls.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }
}

// MARK: - Moderation

enum Moderation {
    static let reasons: [String] = [
        String(localized: "Spam or fake report"),
        String(localized: "Offensive or abusive"),
        String(localized: "Inappropriate photo"),
        String(localized: "Harassment or hate"),
        String(localized: "Shares someone's private information"),
        String(localized: "Something else"),
    ]

    static func flag(_ target: FlagTarget, reason: String) async throws {
        if AppConfig.isDemo { return }
        guard let uid = Auth.auth().currentUser?.uid else { throw BackendError.notSignedIn }
        try await DB.flags.addDocument(data: [
            "reporterId": uid,
            "targetPath": target.path,
            "targetType": target.kind,
            "reason": String(reason.prefix(300)),
            "createdAt": FieldValue.serverTimestamp(),
        ])
    }
}
