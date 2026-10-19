import Foundation

struct Comment: Identifiable, Hashable {
    var id: String
    var authorId: String
    var authorName: String
    var authorPhoto: String?
    var text: String
    var createdAt: Date

    init(_ d: Doc) {
        id = d.id
        authorId = d.string("authorId")
        authorName = d.optString("authorName") ?? String(localized: "Community member")
        authorPhoto = d.optString("authorPhoto")
        text = d.string("text")
        createdAt = d.date("createdAt") ?? .now
    }

    init(id: String, authorId: String, authorName: String, authorPhoto: String?, text: String, createdAt: Date) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.authorPhoto = authorPhoto
        self.text = text
        self.createdAt = createdAt
    }
}

/// Aggregate counters kept by Cloud Functions in `stats/india` and `cityStats/{cityKey}`.
struct ImpactStats: Hashable {
    var reported: Int
    var cleaned: Int
    var bags: Int
    var drives: Int
    var volunteers: Int

    static let zero = ImpactStats(reported: 0, cleaned: 0, bags: 0, drives: 0, volunteers: 0)

    init(reported: Int, cleaned: Int, bags: Int, drives: Int, volunteers: Int) {
        self.reported = reported
        self.cleaned = cleaned
        self.bags = bags
        self.drives = drives
        self.volunteers = volunteers
    }

    init(_ d: Doc) {
        reported = d.int("reported")
        cleaned = d.int("cleaned")
        bags = d.int("bags")
        drives = d.int("drives")
        volunteers = d.int("volunteers")
    }
}

/// What a moderation flag points at.
enum FlagTarget: Hashable {
    case spot(String)
    case drive(String)
    case spotComment(spotId: String, commentId: String)
    case driveComment(driveId: String, commentId: String)
    case profile(String)

    var path: String {
        switch self {
        case .spot(let id): "spots/\(id)"
        case .drive(let id): "drives/\(id)"
        case .spotComment(let s, let c): "spots/\(s)/comments/\(c)"
        case .driveComment(let d, let c): "drives/\(d)/comments/\(c)"
        case .profile(let id): "profiles/\(id)"
        }
    }

    var kind: String {
        switch self {
        case .spot: "spot"
        case .drive: "drive"
        case .spotComment, .driveComment: "comment"
        case .profile: "profile"
        }
    }
}
