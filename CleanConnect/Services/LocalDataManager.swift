// LocalDataManager.swift
// Local data persistence using UserDefaults and JSON files

import Foundation

class LocalDataManager {
    static let shared = LocalDataManager()

    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private init() {
        createDirectoriesIfNeeded()
    }

    private func createDirectoriesIfNeeded() {
        let directories = ["posts", "gatherings", "users", "bookings", "images", "comments"]
        for dir in directories {
            let path = documentsDirectory.appendingPathComponent(dir)
            if !fileManager.fileExists(atPath: path.path) {
                try? fileManager.createDirectory(at: path, withIntermediateDirectories: true)
            }
        }
    }

    // MARK: - Generic Save/Load

    func save<T: Encodable>(_ object: T, to filename: String, in directory: String? = nil) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(object)

        var url = documentsDirectory
        if let dir = directory {
            url = url.appendingPathComponent(dir)
        }
        url = url.appendingPathComponent(filename)

        try data.write(to: url)
    }

    func load<T: Decodable>(_ type: T.Type, from filename: String, in directory: String? = nil) throws -> T {
        var url = documentsDirectory
        if let dir = directory {
            url = url.appendingPathComponent(dir)
        }
        url = url.appendingPathComponent(filename)

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }

    func loadAll<T: Decodable>(_ type: T.Type, from directory: String) throws -> [T] {
        let url = documentsDirectory.appendingPathComponent(directory)
        let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return files.compactMap { fileURL in
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            return try? decoder.decode(type, from: data)
        }
    }

    func delete(filename: String, from directory: String? = nil) throws {
        var url = documentsDirectory
        if let dir = directory {
            url = url.appendingPathComponent(dir)
        }
        url = url.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - UserDefaults Helpers

    func setUserDefault<T: Codable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            userDefaults.set(encoded, forKey: key)
        }
    }

    func getUserDefault<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func removeUserDefault(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }

    // MARK: - Image Storage

    func saveImage(_ data: Data, filename: String) throws -> String {
        let imagesDir = documentsDirectory.appendingPathComponent("images")
        if !fileManager.fileExists(atPath: imagesDir.path) {
            try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        }

        let url = imagesDir.appendingPathComponent(filename)
        try data.write(to: url)
        return url.path
    }

    func loadImage(filename: String) -> Data? {
        let url = documentsDirectory.appendingPathComponent("images").appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }
}

// MARK: - Storage Keys

struct StorageKeys {
    static let currentUser = "currentUser"
    static let isAuthenticated = "isAuthenticated"
    static let posts = "posts"
    static let gatherings = "gatherings"
    static let companies = "cleaningCompanies"
}
