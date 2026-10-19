import Foundation
import FirebaseFirestore

/// Lenient reader over a Firestore document's data.
/// Missing or mistyped fields fall back to defaults instead of failing the whole decode,
/// so one bad field never hides a spot from the map.
struct Doc {
    let id: String
    let data: [String: Any]

    init(id: String, data: [String: Any]) {
        self.id = id
        self.data = data
    }

    init(_ snapshot: DocumentSnapshot) {
        self.id = snapshot.documentID
        self.data = snapshot.data(with: .estimate) ?? [:]
    }

    func string(_ key: String) -> String { data[key] as? String ?? "" }

    func optString(_ key: String) -> String? {
        guard let value = data[key] as? String, !value.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return value
    }

    func int(_ key: String) -> Int { (data[key] as? NSNumber)?.intValue ?? 0 }
    func optInt(_ key: String) -> Int? { (data[key] as? NSNumber)?.intValue }
    func double(_ key: String) -> Double { (data[key] as? NSNumber)?.doubleValue ?? 0 }
    func bool(_ key: String) -> Bool { (data[key] as? NSNumber)?.boolValue ?? false }
    func strings(_ key: String) -> [String] { data[key] as? [String] ?? [] }

    func date(_ key: String) -> Date? {
        if let ts = data[key] as? Timestamp { return ts.dateValue() }
        return data[key] as? Date
    }
}
