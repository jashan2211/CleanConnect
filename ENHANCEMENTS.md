# CleanConnect - Complete App Documentation & Enhancement Guide

> This document contains everything needed to understand, review, and improve the CleanConnect iOS app. It includes architecture details, full source code for key files, and ready-to-use prompts for AI assistants.

---

## PART A: Comprehensive App Explanation

### 1. One-Line Elevator Summary

CleanConnect is an iOS app that gamifies environmental cleanup in India by allowing users to post before/after photos of their cleanup efforts, receive tips from the community, and organize group cleanup events.

---

### 2. Key Features and User Flows

1. **User Authentication** — Simple local auth with name and state/district entry; no password required (demo mode)
2. **Cleanup Post Creation** — Users photograph before/after of cleanup, enter waste collected (kg), duration, location (state/district), and optionally add YouTube/Instagram video proof link
3. **Feed & Discovery** — Scrollable feed of cleanup posts with verification badges, community votes, and engagement metrics
4. **Tipping System** — Users can tip post creators via UPI/Cards (placeholder); includes AI disclaimer warning, 5% platform fee display, and verification status
5. **Community Verification** — Posts display verification badges (Verified, Video Proof, Community Verified, Unverified) based on video proof and community upvotes/downvotes
6. **Community Events (Gatherings)** — Users create/RSVP to cleanup events with date, location, fundraising goals, and WhatsApp group links; safety warnings displayed
7. **Leaderboard** — State/district-level rankings by points earned
8. **Company Services** — Browse/book professional cleaning companies (placeholder)
9. **User Profile** — View stats (total waste collected, points, posts, tips received), edit profile

---

### 3. Architecture Overview

**App Layers:**
- **Presentation Layer (Views):** SwiftUI views organized by feature
- **Business Logic (Services):** Singleton services managing data operations
- **Data Layer:** `LocalDataManager` handles JSON file persistence in Documents directory
- **State Management:** `@StateObject`, `@ObservedObject`, `@EnvironmentObject` patterns

**Major Modules & File Paths:**

| Module | Key Files |
|--------|-----------|
| **App Entry** | `CleanConnect/App/CleanConnectApp.swift`, `CleanConnect/App/ContentView.swift` |
| **Authentication** | `CleanConnect/Services/AuthManager.swift`, `CleanConnect/Views/Auth/AuthView.swift` |
| **User State** | `CleanConnect/Services/UserState.swift`, `CleanConnect/Services/UserService.swift` |
| **Feed/Posts** | `CleanConnect/Views/Feed/FeedView.swift`, `CleanConnect/Views/Feed/PostCard.swift`, `CleanConnect/Views/Feed/CreatePostView.swift`, `CleanConnect/Views/Feed/TipSheet.swift`, `CleanConnect/Views/Feed/PostDetailView.swift` |
| **Post Data** | `CleanConnect/Models/Post.swift`, `CleanConnect/Services/PostService.swift` |
| **Events** | `CleanConnect/Views/Gatherings/GatheringsView.swift`, `CleanConnect/Views/Gatherings/EventDetailView.swift`, `CleanConnect/Views/Gatherings/CreateEventView.swift`, `CleanConnect/Services/GatheringService.swift` |
| **Companies** | `CleanConnect/Views/Companies/CompaniesView.swift`, `CleanConnect/Views/Companies/CompanyDetailView.swift`, `CleanConnect/Views/Companies/BookingSheet.swift`, `CleanConnect/Services/BookingService.swift` |
| **Payments** | `CleanConnect/Services/PaymentService.swift` |
| **Leaderboard** | `CleanConnect/Views/Feed/LeaderboardView.swift`, `CleanConnect/Models/Leaderboard.swift` |
| **Profile** | `CleanConnect/Views/Profile/ProfileView.swift` |
| **Models** | `CleanConnect/Models/User.swift`, `CleanConnect/Models/Post.swift`, `CleanConnect/Models/Gathering.swift`, `CleanConnect/Models/CleaningCompany.swift` |
| **Utilities** | `CleanConnect/Utils/Constants.swift`, `CleanConnect/Utils/LocationManager.swift`, `CleanConnect/Extensions/Extensions.swift` |
| **Data Persistence** | `CleanConnect/Services/LocalDataManager.swift` |

**Data Flow:**
```
View (@State/@StateObject)
    → Service (PostService, GatheringService, etc.)
    → LocalDataManager
    → JSON files in Documents/CleanConnect/
```

---

### 4. Build/Run Steps

```bash
# 1. Open project
open CleanConnect.xcodeproj

# 2. Select scheme: CleanConnect
# 3. Select target device: iPhone 17 Simulator (or any iOS 17+ device)
# 4. Build and run: Cmd+R
```

**Build Configuration:**
- **Xcode Project:** `CleanConnect.xcodeproj`
- **Scheme:** `CleanConnect`
- **Target:** `CleanConnect`
- **Minimum iOS Version:** 17.0
- **Swift Version:** 5.0
- **Bundle Identifier:** `com.cleanconnect.app`
- **Provisioning:** Automatic signing (simulator only; device requires Apple Developer account)
- **Entitlements:** None required currently

---

### 5. Third-Party Libraries/Packages

**None.** The app is built entirely with native Apple frameworks:
- SwiftUI (UI)
- Foundation (Data handling)
- CoreLocation (Location services)
- PhotosUI (Image picker)
- UIKit (Interop for `UIApplication.shared.open()`)

No Swift Package Manager dependencies, CocoaPods, or Carthage.

---

### 6. Persistent Data & Models

**Storage Mechanism:** JSON files in `Documents/CleanConnect/` directory via `LocalDataManager.swift`

**Key Models:**

| Model | File | Key Properties |
|-------|------|----------------|
| `User` | `CleanConnect/Models/User.swift` | `id`, `displayName`, `state`, `district`, `totalPoints`, `totalWasteKg`, `tipsReceived` |
| `Post` | `CleanConnect/Models/Post.swift` | `id`, `userId`, `userName`, `description`, `beforeImageURL`, `afterImageURL`, `videoProofURL`, `wasteCollectedKg`, `pointsEarned`, `state`, `district`, `likes`, `tipsReceived`, `verified`, `verificationBadge`, `communityVotes`, `communityDownvotes`, `hasVideoProof`, `aiVerificationStatus` |
| `Gathering` | `CleanConnect/Models/Gathering.swift` | `id`, `organizerId`, `title`, `description`, `eventDate`, `state`, `district`, `attendeesCount`, `fundraisingGoal`, `fundraisingRaised`, `whatsappGroupLink` |
| `CleaningCompany` | `CleanConnect/Models/CleaningCompany.swift` | `id`, `name`, `description`, `services`, `rating`, `priceRange` |
| `Tip` | `CleanConnect/Models/Post.swift` | `id`, `postId`, `senderId`, `recipientId`, `amount`, `platformFee`, `status` |
| `Comment` | `CleanConnect/Models/Post.swift` | `id`, `postId`, `userId`, `text`, `likes`, `createdAt` |

**Enums:**
- `AIVerificationStatus`: `pending`, `likely_genuine`, `possibly_ai`, `likely_ai`, `not_analyzed`
- `VerificationBadge`: `verified`, `videoProof`, `communityVerified`, `unverified`

**Storage Locations:**
- User data: `Documents/CleanConnect/user_<id>.json`
- Posts: `Documents/CleanConnect/posts/<postId>.json`
- Images: `Documents/CleanConnect/images/<filename>.jpg`
- Auth state: `UserDefaults` keys `current_user_id`, `is_authenticated`

---

### 7. Networking & External Services

**Currently: None.** The app is fully offline/local-only.

**Placeholder Services (not implemented):**
- **Payment Gateway:** `PaymentService.swift` has placeholder for Razorpay/UPI integration
- **Video Proof Links:** Users paste YouTube/Instagram URLs; app opens via `UIApplication.shared.open(url)`

**No API Keys or Secrets** are currently stored anywhere.

**Future Integration Points:**
- Razorpay SDK for payments (would require `Secrets.xcconfig` or similar)
- Firebase/Supabase for cloud storage and auth
- AI image verification API

---

### 8. Tests / CI / Code Quality

**Current State:**
- **Unit Tests:** None
- **UI Tests:** None
- **CI/CD:** None configured
- **Linting:** None (no SwiftLint)
- **Test Files:** No `Tests/` directory exists

**Recommendation:** Add XCTest targets for services and UI tests for critical flows.

---

### 9. UI/UX Notes

**Design System:**
- **Colors:** Indian tricolor theme defined in `Extensions.swift`:
  - `.ccSaffron` (#FF9933) — Primary accent
  - `.ccIndiaGreen` (#138808) — Secondary accent
  - `.ccTipGold` (#F59E0B) — Tips/rewards
  - `.ccAIWarning` (#8B5CF6) — AI warning purple
  - `.ccGreen` (#22C55E) — Success states
- **Gradients:** `tricolorGradient`, `greenGradient`, `tipGradient`

**Screens (11 total):**
1. AuthView (login/signup)
2. ContentView (tab container)
3. FeedView (main feed)
4. PostCard (feed item)
5. CreatePostView
6. PostDetailView
7. TipSheet
8. LeaderboardView
9. GatheringsView / EventDetailView / CreateEventView
10. CompaniesView / CompanyDetailView / BookingSheet
11. ProfileView

**Animations:** Standard SwiftUI transitions; no custom animations

**Accessibility:** Not implemented (no VoiceOver labels, dynamic type testing, or accessibility identifiers)

---

### 10. Known Bugs / TODOs / Technical Debt

| Issue | File | Description |
|-------|------|-------------|
| Unused result warning | `TipSheet.swift:319` | `createTip()` result not awaited properly |
| No image caching | `PostCard.swift`, `ImageWithLabel` | `AsyncImage` has no persistent cache |
| Comments not persisted | `PostService.swift:287-304` | `addComment()` returns comment but doesn't save |
| No actual payment flow | `PaymentService.swift` | All payment methods are placeholders |
| Hardcoded sample data | `PostService.swift`, `GatheringService.swift` | Demo data created on first launch |
| No error recovery UI | Multiple views | Errors shown via alerts only |
| Location permission UX | `LocationManager.swift` | No graceful degradation if denied |
| Video URL validation | `CreatePostView.swift` | No validation that URL is valid YouTube/Instagram |
| Images stored locally forever | `LocalDataManager.swift` | No cleanup of orphaned images |
| No deep linking | N/A | Cannot share posts via URL |

---

### 11. Suggested First Priority Improvements

1. **Add Unit Tests for Services** — `PostService`, `AuthManager`, `LocalDataManager` have zero test coverage; critical for reliability
2. **Implement Image Caching** — Use `NSCache` or third-party like Kingfisher; current `AsyncImage` re-downloads every scroll
3. **Add Input Validation** — Video proof URLs, waste amounts, and user inputs have no validation
4. **Implement Real Payment Flow** — Integrate Razorpay SDK with test mode for functional tip flow
5. **Add Accessibility** — VoiceOver labels, dynamic type support; required for App Store and inclusive design

---

## PART B1: Concise Forward Prompt (copy-paste ready)

```
ChatGPT, I need you to write a developer-ready prompt for improving an iOS app.

App: CleanConnect — a SwiftUI app for gamifying environmental cleanup in India. Users post before/after cleanup photos, receive tips, and join community events. Local-only storage, no backend, iOS 17+, Swift 5.

Top 5 improvements needed:
1. Add unit tests for PostService, AuthManager, LocalDataManager
2. Implement image caching (AsyncImage re-downloads on every scroll)
3. Add input validation for video URLs and user inputs
4. Integrate Razorpay SDK for real payment flow
5. Add VoiceOver accessibility labels

Constraints: Keep local-only architecture. No backend changes. Must build on iOS 17+ simulator.

Deliverable: Write me a prompt I can paste into ChatGPT that requests implementation of these improvements. Produce two versions: (1) a short instruction prompt, and (2) a detailed task-tracked prompt with acceptance criteria, tests to run, and example commit messages.
```

---

## PART B2: Detailed Forward Prompt (copy-paste ready)

```
ChatGPT, I need your help creating a developer-ready prompt for improving an iOS app called CleanConnect.

## App Summary
CleanConnect is a SwiftUI iOS app that gamifies environmental cleanup efforts in India. Users post before/after photos of their cleanup work, receive monetary tips from the community, and organize/attend group cleanup events. The app uses local JSON file storage with no backend dependency.

## Tech Stack
- Language: Swift 5.0
- UI Framework: SwiftUI
- Minimum iOS: 17.0
- Storage: Local JSON files via custom LocalDataManager
- Third-party packages: None (pure Apple frameworks)
- Xcode Project: CleanConnect.xcodeproj
- Target/Scheme: CleanConnect
- Bundle ID: com.cleanconnect.app

## Key Source Files
- Entry: CleanConnect/App/CleanConnectApp.swift
- Models: CleanConnect/Models/Post.swift, User.swift, Gathering.swift
- Services: CleanConnect/Services/PostService.swift, AuthManager.swift, LocalDataManager.swift
- Views: CleanConnect/Views/Feed/PostCard.swift, TipSheet.swift, CreatePostView.swift
- Extensions: CleanConnect/Extensions/Extensions.swift

## Top 5 Improvement Priorities (implement in order)

1. **Add Unit Tests** — Create XCTest targets for PostService, AuthManager, and LocalDataManager. Rationale: Zero test coverage currently; services handle all data logic.

2. **Implement Image Caching** — Replace raw AsyncImage with NSCache-backed solution or integrate Kingfisher. Rationale: Images re-download on every scroll causing poor performance.

3. **Add Input Validation** — Validate video proof URLs (must be youtube.com or instagram.com), waste collected amounts (positive numbers), and text inputs (length limits, XSS prevention). Rationale: No validation exists; users can enter invalid data.

4. **Integrate Razorpay Payment SDK** — Add Razorpay iOS SDK, implement test mode payment flow in PaymentService.swift. Rationale: Tipping is core feature but currently placeholder-only.

5. **Add Accessibility Support** — Add accessibilityLabel, accessibilityHint to all interactive elements; test with VoiceOver. Rationale: Required for App Store and inclusive design.

## Constraints
- MUST keep local-only architecture (no Firebase, no backend APIs)
- MUST maintain iOS 17+ compatibility
- MUST NOT break existing functionality
- NO new Swift Package dependencies except Razorpay SDK for priority #4
- Keep existing Indian tricolor design system (ccSaffron, ccIndiaGreen colors)

## Testing & Validation Requirements
- All new unit tests must pass
- App must build successfully on iOS 17+ simulator
- Existing sample data must still load
- UI must not regress visually (manual check)
- VoiceOver must announce all buttons and inputs correctly

## Your Task
Write me a prompt that I can paste into ChatGPT which requests implementation of these five improvements. The prompt you create must include:

1. **Short Instruction Prompt** (under 100 words) — A quick prompt a developer can paste for fast iteration

2. **Detailed Task-Tracked Prompt** (300-500 words) that includes:
   - Clear acceptance criteria per improvement
   - Specific tests to run after each change
   - Example commit messages following conventional commits format
   - File paths that will be modified
   - Rollback instructions if something breaks

## Expected Output Format
Return your response with these labeled sections:
- SHORT PROMPT: [copy-paste ready]
- DETAILED PROMPT: [copy-paste ready]
- SUGGESTED FIRST COMMIT MESSAGE: [example]
- FILES TO ATTACH: [list of files the developer should share with ChatGPT when using the prompt]
```

---

## KEY SOURCE FILES (Complete Code)

The following sections contain the full source code of critical files for reference.

---

### File: CleanConnect/Models/Post.swift

```swift
// Post.swift
// Cleanup post model

import Foundation

struct Post: Codable, Identifiable {
    let id: String
    let userId: String
    let userName: String
    let userPhotoURL: String?

    // Content
    var description: String
    var beforeImageURL: String?
    var afterImageURL: String?
    var videoProofURL: String?         // YouTube/Instagram link for video proof

    // Stats
    var wasteCollectedKg: Double
    var durationMinutes: Int?
    var pointsEarned: Int

    // Location
    var state: String
    var district: String
    var pincode: String?
    var latitude: Double?
    var longitude: Double?
    var address: String?

    // Engagement
    var likes: Int
    var comments: Int
    var shares: Int
    var tipsReceived: Int

    // Verification Status
    var verified: Bool                 // Has video proof
    var verificationScore: Double?     // AI confidence score (0-1)
    var communityVotes: Int            // Upvotes from community
    var communityDownvotes: Int        // Downvotes (flagged as fake)
    var hasVideoProof: Bool            // Quick check for video
    var aiVerificationStatus: AIVerificationStatus  // AI analysis result
    var isLiked: Bool

    // Metadata
    var createdAt: Date
    var updatedAt: Date?

    // Tags
    var hashtags: [String]?
    var campaignId: String?

    enum CodingKeys: String, CodingKey {
        case id, userId, userName, userPhotoURL
        case description, beforeImageURL, afterImageURL, videoProofURL
        case wasteCollectedKg, durationMinutes, pointsEarned
        case state, district, pincode, latitude, longitude, address
        case likes, comments, shares, tipsReceived
        case verified, verificationScore, communityVotes, communityDownvotes
        case hasVideoProof, aiVerificationStatus, isLiked
        case createdAt, updatedAt
        case hashtags, campaignId
    }

    // Computed property for verification badge type
    var verificationBadge: VerificationBadge {
        if hasVideoProof && communityVotes > 5 && communityDownvotes < 2 {
            return .verified
        } else if hasVideoProof {
            return .videoProof
        } else if communityVotes > 10 {
            return .communityVerified
        } else {
            return .unverified
        }
    }
}

// AI Verification Status
enum AIVerificationStatus: String, Codable {
    case pending = "pending"
    case likely_genuine = "likely_genuine"
    case possibly_ai = "possibly_ai"
    case likely_ai = "likely_ai"
    case not_analyzed = "not_analyzed"

    var displayText: String {
        switch self {
        case .pending: return "Analyzing..."
        case .likely_genuine: return "Looks genuine"
        case .possibly_ai: return "May be AI-generated"
        case .likely_ai: return "Likely AI-generated"
        case .not_analyzed: return "Not analyzed"
        }
    }

    var color: String {
        switch self {
        case .pending: return "gray"
        case .likely_genuine: return "green"
        case .possibly_ai: return "orange"
        case .likely_ai: return "red"
        case .not_analyzed: return "gray"
        }
    }
}

// Verification Badge Types
enum VerificationBadge: String, Codable {
    case verified = "verified"           // Video proof + community approval
    case videoProof = "video_proof"      // Has video proof only
    case communityVerified = "community" // High community votes
    case unverified = "unverified"       // No verification

    var icon: String {
        switch self {
        case .verified: return "checkmark.seal.fill"
        case .videoProof: return "video.fill"
        case .communityVerified: return "person.2.fill"
        case .unverified: return "questionmark.circle"
        }
    }

    var color: String {
        switch self {
        case .verified: return "blue"
        case .videoProof: return "green"
        case .communityVerified: return "orange"
        case .unverified: return "gray"
        }
    }
}

// MARK: - Post Preview
extension Post {
    static let preview = Post(
        id: "preview-post",
        userId: "user-1",
        userName: "Test User",
        userPhotoURL: nil,
        description: "Cleaned up the local beach today! Found a lot of plastic waste. Let's keep our beaches clean!",
        beforeImageURL: nil,
        afterImageURL: nil,
        videoProofURL: "https://youtube.com/shorts/example",
        wasteCollectedKg: 5.5,
        durationMinutes: 45,
        pointsEarned: 75,
        state: "Maharashtra",
        district: "Mumbai",
        pincode: "400001",
        latitude: 19.0760,
        longitude: 72.8777,
        address: "Juhu Beach",
        likes: 24,
        comments: 5,
        shares: 3,
        tipsReceived: 100,
        verified: true,
        verificationScore: 0.95,
        communityVotes: 15,
        communityDownvotes: 1,
        hasVideoProof: true,
        aiVerificationStatus: .likely_genuine,
        isLiked: false,
        createdAt: Date().addingTimeInterval(-3600),
        updatedAt: nil,
        hashtags: ["BeachCleanup", "CleanMumbai"],
        campaignId: nil
    )
}

struct Comment: Codable, Identifiable {
    let id: String
    let postId: String
    let userId: String
    let userName: String
    let userPhotoURL: String?
    var text: String
    var likes: Int
    var createdAt: Date

    static let preview = Comment(
        id: "comment-1",
        postId: "post-1",
        userId: "user-2",
        userName: "Jane Doe",
        userPhotoURL: nil,
        text: "Great work! Keep it up!",
        likes: 3,
        createdAt: Date().addingTimeInterval(-1800)
    )
}

struct Tip: Codable, Identifiable {
    let id: String
    let postId: String
    let senderId: String
    let senderName: String
    let recipientId: String
    let recipientName: String
    var amount: Int
    var platformFee: Int
    var creatorReceives: Int
    var status: TipStatus
    var paymentId: String?
    var createdAt: Date

    enum TipStatus: String, Codable {
        case pending
        case completed
        case failed
        case refunded
    }
}

// Point values matching web app
struct PointValues {
    static let postCreated = 50
    static let eventOrganized = 100
    static let eventAttended = 25
    static let tipReceivedPer10 = 1 // +1 pt per Rs.10 received
}
```

---

### File: CleanConnect/Models/User.swift

```swift
// User.swift
// User model for local storage

import Foundation

struct User: Codable, Identifiable {
    let id: String
    var email: String?
    var phone: String?
    var displayName: String
    var photoURL: String?
    var bio: String?

    // Location
    var state: String
    var district: String
    var pincode: String?

    // Stats
    var totalPoints: Int
    var totalWasteKg: Double
    var totalCleanups: Int
    var eventsAttended: Int
    var eventsOrganized: Int
    var tipsReceived: Int
    var tipsSent: Int

    // Streaks
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date?

    // Badges
    var badges: [String]
    var level: Int

    // Settings
    var notificationsEnabled: Bool
    var isPrivate: Bool

    // UPI for receiving tips
    var upiId: String?

    // Metadata
    var createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, phone, displayName, photoURL, bio
        case state, district, pincode
        case totalPoints, totalWasteKg, totalCleanups
        case eventsAttended, eventsOrganized, tipsReceived, tipsSent
        case currentStreak, longestStreak, lastActiveDate
        case badges, level
        case notificationsEnabled, isPrivate, upiId
        case createdAt, updatedAt
    }
}

// MARK: - User Extensions
extension User {
    static let preview = User(
        id: "preview-user",
        email: "test@example.com",
        phone: "9876543210",
        displayName: "Test User",
        photoURL: nil,
        bio: "Keeping India clean!",
        state: "Maharashtra",
        district: "Mumbai",
        pincode: "400001",
        totalPoints: 1250,
        totalWasteKg: 45.5,
        totalCleanups: 12,
        eventsAttended: 5,
        eventsOrganized: 2,
        tipsReceived: 500,
        tipsSent: 100,
        currentStreak: 7,
        longestStreak: 14,
        lastActiveDate: Date(),
        badges: ["first_cleanup", "week_warrior"],
        level: 5,
        notificationsEnabled: true,
        isPrivate: false,
        upiId: "test@upi",
        createdAt: Date().addingTimeInterval(-86400 * 30),
        updatedAt: Date()
    )

    var levelTitle: String {
        switch level {
        case 1: return "Beginner"
        case 2: return "Cleaner"
        case 3: return "Warrior"
        case 4: return "Champion"
        case 5: return "Hero"
        case 6...10: return "Legend"
        default: return "Newbie"
        }
    }
}
```

---

### File: CleanConnect/Services/LocalDataManager.swift

```swift
// LocalDataManager.swift
// Handles all local data persistence

import Foundation

class LocalDataManager {
    static let shared = LocalDataManager()

    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CleanConnect")
    }

    private init() {
        createDirectoryIfNeeded()
    }

    private func createDirectoryIfNeeded() {
        let directories = ["", "posts", "gatherings", "users", "images"]
        for dir in directories {
            let path = documentsDirectory.appendingPathComponent(dir)
            if !fileManager.fileExists(atPath: path.path) {
                try? fileManager.createDirectory(at: path, withIntermediateDirectories: true)
            }
        }
    }

    // MARK: - Generic CRUD Operations

    func save<T: Encodable>(_ item: T, to filename: String, in subdirectory: String = "") throws {
        let url = documentsDirectory
            .appendingPathComponent(subdirectory)
            .appendingPathComponent(filename)

        let data = try JSONEncoder().encode(item)
        try data.write(to: url)
    }

    func load<T: Decodable>(_ type: T.Type, from filename: String, in subdirectory: String = "") throws -> T {
        let url = documentsDirectory
            .appendingPathComponent(subdirectory)
            .appendingPathComponent(filename)

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }

    func delete(filename: String, in subdirectory: String = "") throws {
        let url = documentsDirectory
            .appendingPathComponent(subdirectory)
            .appendingPathComponent(filename)

        try fileManager.removeItem(at: url)
    }

    func loadAll<T: Decodable>(_ type: T.Type, from subdirectory: String) throws -> [T] {
        let directoryURL = documentsDirectory.appendingPathComponent(subdirectory)

        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return []
        }

        let files = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)

        return files.compactMap { url -> T? in
            guard url.pathExtension == "json" else { return nil }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(type, from: data)
        }
    }

    // MARK: - Image Operations

    func saveImage(_ data: Data, filename: String) throws -> String {
        let url = documentsDirectory
            .appendingPathComponent("images")
            .appendingPathComponent(filename)

        try data.write(to: url)
        return url.path
    }

    func loadImage(filename: String) -> Data? {
        let url = documentsDirectory
            .appendingPathComponent("images")
            .appendingPathComponent(filename)

        return try? Data(contentsOf: url)
    }

    func deleteImage(filename: String) {
        let url = documentsDirectory
            .appendingPathComponent("images")
            .appendingPathComponent(filename)

        try? fileManager.removeItem(at: url)
    }

    // MARK: - Utility

    func fileExists(_ filename: String, in subdirectory: String = "") -> Bool {
        let url = documentsDirectory
            .appendingPathComponent(subdirectory)
            .appendingPathComponent(filename)

        return fileManager.fileExists(atPath: url.path)
    }

    func clearAllData() throws {
        if fileManager.fileExists(atPath: documentsDirectory.path) {
            try fileManager.removeItem(at: documentsDirectory)
        }
        createDirectoryIfNeeded()
    }
}
```

---

### File: CleanConnect/Services/PostService.swift

```swift
// PostService.swift
// Post-related local operations

import Foundation

class PostService {
    static let shared = PostService()
    private let dataManager = LocalDataManager.shared

    private init() {
        // Load sample posts if none exist
        loadSampleDataIfNeeded()
    }

    private func loadSampleDataIfNeeded() {
        let posts = (try? dataManager.loadAll(Post.self, from: "posts")) ?? []
        if posts.isEmpty {
            // Create sample posts for demo
            createSamplePosts()
        }
    }

    private func createSamplePosts() {
        let samplePosts = [
            // Verified with video proof
            Post(
                id: UUID().uuidString,
                userId: "sample-user-1",
                userName: "Rajesh Kumar",
                userPhotoURL: nil,
                description: "Cleaned up Juhu Beach today! Collected plastic bottles, wrappers, and other waste. Watch my video for full cleanup journey! #BeachCleanup #CleanMumbai #SwachhBharat",
                beforeImageURL: nil,
                afterImageURL: nil,
                videoProofURL: "https://youtube.com/shorts/juhu_cleanup_demo",
                wasteCollectedKg: 5.5,
                durationMinutes: 45,
                pointsEarned: 75,
                state: "Maharashtra",
                district: "Mumbai",
                pincode: "400049",
                latitude: 19.0883,
                longitude: 72.8264,
                address: "Juhu Beach",
                likes: 24,
                comments: 5,
                shares: 3,
                tipsReceived: 350,
                verified: true,
                verificationScore: 0.95,
                communityVotes: 18,
                communityDownvotes: 0,
                hasVideoProof: true,
                aiVerificationStatus: .likely_genuine,
                isLiked: false,
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: nil,
                hashtags: ["BeachCleanup", "CleanMumbai", "SwachhBharat"],
                campaignId: nil
            ),
            // Community verified (no video but trusted)
            Post(
                id: UUID().uuidString,
                userId: "sample-user-2",
                userName: "Priya Sharma",
                userPhotoURL: nil,
                description: "Morning cleanup at Lodhi Garden. Found so much plastic waste hidden in bushes. Together we can make Delhi greener! #SwachhBharat #CleanDelhi",
                beforeImageURL: nil,
                afterImageURL: nil,
                videoProofURL: nil,
                wasteCollectedKg: 3.2,
                durationMinutes: 60,
                pointsEarned: 65,
                state: "Delhi",
                district: "South Delhi",
                pincode: "110003",
                latitude: 28.5933,
                longitude: 77.2190,
                address: "Lodhi Garden",
                likes: 45,
                comments: 12,
                shares: 8,
                tipsReceived: 150,
                verified: false,
                verificationScore: nil,
                communityVotes: 32,
                communityDownvotes: 2,
                hasVideoProof: false,
                aiVerificationStatus: .not_analyzed,
                isLiked: false,
                createdAt: Date().addingTimeInterval(-7200),
                updatedAt: nil,
                hashtags: ["SwachhBharat", "CleanDelhi"],
                campaignId: nil
            ),
            // Verified with video, high tips
            Post(
                id: UUID().uuidString,
                userId: "sample-user-3",
                userName: "Arjun Patel",
                userPhotoURL: nil,
                description: "Weekend cleanup drive at Sabarmati Riverfront. Amazing to see so many volunteers! Full video on my Instagram! #CleanGujarat #RiverCleanup",
                beforeImageURL: nil,
                afterImageURL: nil,
                videoProofURL: "https://instagram.com/reel/sabarmati_cleanup",
                wasteCollectedKg: 8.0,
                durationMinutes: 90,
                pointsEarned: 100,
                state: "Gujarat",
                district: "Ahmedabad",
                pincode: "380001",
                latitude: 23.0225,
                longitude: 72.5714,
                address: "Sabarmati Riverfront",
                likes: 67,
                comments: 18,
                shares: 15,
                tipsReceived: 750,
                verified: true,
                verificationScore: 0.98,
                communityVotes: 45,
                communityDownvotes: 1,
                hasVideoProof: true,
                aiVerificationStatus: .likely_genuine,
                isLiked: false,
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: nil,
                hashtags: ["CleanGujarat", "RiverCleanup"],
                campaignId: nil
            ),
            // Unverified post (no video, low votes)
            Post(
                id: UUID().uuidString,
                userId: "sample-user-4",
                userName: "New User",
                userPhotoURL: nil,
                description: "Cleaned my neighborhood park today. Small effort but makes a difference!",
                beforeImageURL: nil,
                afterImageURL: nil,
                videoProofURL: nil,
                wasteCollectedKg: 1.5,
                durationMinutes: 30,
                pointsEarned: 50,
                state: "Karnataka",
                district: "Bangalore",
                pincode: "560001",
                latitude: 12.9716,
                longitude: 77.5946,
                address: "Cubbon Park",
                likes: 5,
                comments: 2,
                shares: 0,
                tipsReceived: 0,
                verified: false,
                verificationScore: nil,
                communityVotes: 3,
                communityDownvotes: 0,
                hasVideoProof: false,
                aiVerificationStatus: .not_analyzed,
                isLiked: false,
                createdAt: Date().addingTimeInterval(-1800),
                updatedAt: nil,
                hashtags: ["CleanBangalore"],
                campaignId: nil
            )
        ]

        for post in samplePosts {
            try? dataManager.save(post, to: "\(post.id).json", in: "posts")
        }
    }

    func createPost(
        description: String,
        wasteCollectedKg: Double,
        durationMinutes: Int?,
        state: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        beforeImageData: Data?,
        afterImageData: Data?,
        videoProofURL: String?
    ) async throws {
        guard let userId = await AuthManager.shared.currentUserId else {
            throw PostError.notAuthenticated
        }

        let userName = await UserState.shared.currentUser?.displayName ?? "User"
        let postId = UUID().uuidString

        // Posts with video proof get bonus points
        let hasVideo = videoProofURL != nil && !videoProofURL!.isEmpty
        let points = hasVideo ? PointValues.postCreated + 25 : PointValues.postCreated

        // Save images if provided
        var beforeURL: String?
        var afterURL: String?

        if let data = beforeImageData {
            beforeURL = try? dataManager.saveImage(data, filename: "\(postId)_before.jpg")
        }
        if let data = afterImageData {
            afterURL = try? dataManager.saveImage(data, filename: "\(postId)_after.jpg")
        }

        let post = Post(
            id: postId,
            userId: userId,
            userName: userName,
            userPhotoURL: nil,
            description: description,
            beforeImageURL: beforeURL,
            afterImageURL: afterURL,
            videoProofURL: videoProofURL,
            wasteCollectedKg: wasteCollectedKg,
            durationMinutes: durationMinutes,
            pointsEarned: points,
            state: state,
            district: district,
            pincode: nil,
            latitude: latitude,
            longitude: longitude,
            address: nil,
            likes: 0,
            comments: 0,
            shares: 0,
            tipsReceived: 0,
            verified: hasVideo,
            verificationScore: nil,
            communityVotes: 0,
            communityDownvotes: 0,
            hasVideoProof: hasVideo,
            aiVerificationStatus: .not_analyzed,
            isLiked: false,
            createdAt: Date(),
            updatedAt: nil,
            hashtags: extractHashtags(from: description),
            campaignId: nil
        )

        try dataManager.save(post, to: "\(postId).json", in: "posts")

        // Update user stats
        try await UserState.shared.updateStats(points: points, wasteKg: wasteCollectedKg)
    }

    private func extractHashtags(from text: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: "#\\w+", options: [])
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex?.matches(in: text, options: [], range: range) ?? []

        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range]).lowercased()
        }
    }

    func getPosts(state: String? = nil, district: String? = nil, limit: Int = 20) async throws -> [Post] {
        var posts = (try? dataManager.loadAll(Post.self, from: "posts")) ?? []

        // Filter by state/district if specified
        if let state = state {
            posts = posts.filter { $0.state == state }
        }
        if let district = district {
            posts = posts.filter { $0.district == district }
        }

        // Sort by date (newest first) and limit
        return Array(posts.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }

    func likePost(postId: String) async throws {
        guard var post = try? dataManager.load(Post.self, from: "\(postId).json", in: "posts") else { return }
        post.likes += 1
        post.isLiked = true
        try dataManager.save(post, to: "\(postId).json", in: "posts")
    }

    func unlikePost(postId: String) async throws {
        guard var post = try? dataManager.load(Post.self, from: "\(postId).json", in: "posts") else { return }
        post.likes = max(0, post.likes - 1)
        post.isLiked = false
        try dataManager.save(post, to: "\(postId).json", in: "posts")
    }

    func getComments(postId: String) async throws -> [Comment] {
        // Return empty for now - comments stored per post
        return []
    }

    func addComment(postId: String, userId: String, userName: String, userPhotoURL: String?, text: String) async throws -> Comment {
        let comment = Comment(
            id: UUID().uuidString,
            postId: postId,
            userId: userId,
            userName: userName,
            userPhotoURL: userPhotoURL,
            text: text,
            likes: 0,
            createdAt: Date()
        )
        return comment
    }
}

enum PostError: LocalizedError {
    case notAuthenticated
    case uploadFailed
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in to create a post"
        case .uploadFailed: return "Failed to upload image"
        case .invalidData: return "Invalid post data"
        }
    }
}
```

---

### File: CleanConnect/Services/AuthManager.swift

```swift
// AuthManager.swift
// Local authentication manager

import Foundation

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUserId: String?

    private let defaults = UserDefaults.standard
    private let userIdKey = "current_user_id"
    private let authKey = "is_authenticated"

    private init() {
        // Check for existing session
        self.currentUserId = defaults.string(forKey: userIdKey)
        self.isAuthenticated = defaults.bool(forKey: authKey)
    }

    func signIn(name: String, state: String, district: String) async throws {
        // Create or get user
        let userId = UUID().uuidString

        let user = User(
            id: userId,
            email: nil,
            phone: nil,
            displayName: name,
            photoURL: nil,
            bio: nil,
            state: state,
            district: district,
            pincode: nil,
            totalPoints: 0,
            totalWasteKg: 0,
            totalCleanups: 0,
            eventsAttended: 0,
            eventsOrganized: 0,
            tipsReceived: 0,
            tipsSent: 0,
            currentStreak: 0,
            longestStreak: 0,
            lastActiveDate: Date(),
            badges: [],
            level: 1,
            notificationsEnabled: true,
            isPrivate: false,
            upiId: nil,
            createdAt: Date(),
            updatedAt: nil
        )

        // Save user locally
        try LocalDataManager.shared.save(user, to: "user_\(userId).json", in: "users")

        // Update state
        self.currentUserId = userId
        self.isAuthenticated = true

        // Persist
        defaults.set(userId, forKey: userIdKey)
        defaults.set(true, forKey: authKey)

        // Update UserState
        await UserState.shared.loadUser(userId: userId)
    }

    func signOut() {
        currentUserId = nil
        isAuthenticated = false
        defaults.removeObject(forKey: userIdKey)
        defaults.set(false, forKey: authKey)
    }
}
```

---

### File: CleanConnect/Services/PaymentService.swift

```swift
// PaymentService.swift
// Payment and tipping placeholder service

import Foundation

class PaymentService {
    static let shared = PaymentService()
    private let dataManager = LocalDataManager.shared

    private init() {}

    // Platform fee percentage
    let platformFeePercent = 0.05

    func createTip(postId: String, recipientId: String, amount: Int) async throws -> Tip {
        guard let senderId = await AuthManager.shared.currentUserId else {
            throw PaymentError.notAuthenticated
        }

        let senderName = await UserState.shared.currentUser?.displayName ?? "Anonymous"

        // Calculate fees
        let platformFee = Int(Double(amount) * platformFeePercent)
        let creatorReceives = amount - platformFee

        let tip = Tip(
            id: UUID().uuidString,
            postId: postId,
            senderId: senderId,
            senderName: senderName,
            recipientId: recipientId,
            recipientName: "", // Would fetch from user
            amount: amount,
            platformFee: platformFee,
            creatorReceives: creatorReceives,
            status: .completed, // Demo: instant completion
            paymentId: "demo_\(UUID().uuidString)",
            createdAt: Date()
        )

        // In real app: integrate Razorpay here
        // For demo, just simulate success

        return tip
    }

    func getPaymentMethods() -> [PaymentMethod] {
        return [
            PaymentMethod(id: "upi", name: "UPI", icon: "indianrupeesign.circle"),
            PaymentMethod(id: "card", name: "Card", icon: "creditcard"),
            PaymentMethod(id: "netbanking", name: "Net Banking", icon: "building.columns")
        ]
    }
}

struct PaymentMethod: Identifiable {
    let id: String
    let name: String
    let icon: String
}

enum PaymentError: LocalizedError {
    case notAuthenticated
    case paymentFailed
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please sign in to send tips"
        case .paymentFailed: return "Payment failed. Please try again."
        case .invalidAmount: return "Invalid tip amount"
        }
    }
}
```

---

### File: CleanConnect/Extensions/Extensions.swift

```swift
// Extensions.swift
// Swift extensions for the app

import SwiftUI

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // CleanConnect theme colors - Indian Tricolor inspired
    static let ccGreen = Color(hex: "22C55E")
    static let ccGreenDark = Color(hex: "16A34A")
    static let ccSaffron = Color(hex: "FF9933")      // Indian flag saffron
    static let ccIndiaGreen = Color(hex: "138808")   // Indian flag green
    static let ccWhite = Color.white

    // Accent colors
    static let ccTipGold = Color(hex: "F59E0B")      // Gold for tips
    static let ccVerified = Color(hex: "3B82F6")     // Blue verified
    static let ccWarning = Color(hex: "EF4444")      // Warning red
    static let ccAIWarning = Color(hex: "8B5CF6")    // Purple for AI warning

    // Gradients
    static var tricolorGradient: LinearGradient {
        LinearGradient(
            colors: [ccSaffron, ccWhite, ccIndiaGreen],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var greenGradient: LinearGradient {
        LinearGradient(
            colors: [ccGreen, ccGreenDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var tipGradient: LinearGradient {
        LinearGradient(
            colors: [ccSaffron, ccTipGold],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Date Extensions

extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions

extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }

    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }

    var isValidPhone: Bool {
        let phoneRegex = "^[6-9]\\d{9}$" // Indian mobile number
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return predicate.evaluate(with: self)
    }
}

// MARK: - View Extensions

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Number Extensions

extension Int {
    func abbreviated() -> String {
        if self >= 1_000_000 {
            return String(format: "%.1fM", Double(self) / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "%.1fK", Double(self) / 1_000)
        }
        return "\(self)"
    }

    func toINR() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "₹\(self)"
    }
}

// MARK: - Array Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Encodable Extension

extension Encodable {
    func asDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
```

---

## Original Enhancement Recommendations

### Priority 1: Critical Fixes Before Release

#### 1.1 Image Handling
**Current State**: Images saved locally but no caching
**Enhancement**: Implement NSCache-backed image loader or integrate Kingfisher

#### 1.2 Location Services
**Current State**: LocationManager exists but basic
**Enhancement**:
- Request location permission on first post
- Auto-fill state/district from coordinates
- Show cleanup locations on map

#### 1.3 App Icons & Launch Screen
**Current State**: Placeholder assets
**Enhancement**:
- Design green leaf-themed icon with Indian tricolor accent
- Add launch screen with animation
- Support all device sizes

---

### Priority 2: User Experience Improvements

#### 2.1 Onboarding Flow
- Add 3-4 swipeable intro screens
- Highlight key features (posts, events, points)
- Show Swachh Bharat connection

#### 2.2 Empty States
- Add illustrations for empty feeds
- Motivational messages
- "No posts in your area? Be the first!"

#### 2.3 Skeleton Loading
```swift
struct SkeletonCard: View {
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .shimmer()
        }
    }
}
```

---

### Priority 3: India Market Fit

#### 3.1 Regional Languages
- Hindi (primary)
- Tamil, Telugu, Kannada, Malayalam (South)
- Use `Localizable.strings` for all UI text

#### 3.2 WhatsApp Integration
```swift
func shareToWhatsApp(text: String) {
    let urlString = "whatsapp://send?text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
    if let url = URL(string: urlString) {
        UIApplication.shared.open(url)
    }
}
```

#### 3.3 Low Data Mode
- Compressed image uploads
- Text-only feed option
- Offline caching
- Background sync when on WiFi

---

### Priority 4: Gamification Enhancements

#### 4.1 Daily Challenges
```swift
struct DailyChallenge: Codable {
    let id: String
    let title: String
    let description: String
    let targetWasteKg: Double
    let bonusPoints: Int
    let expiresAt: Date
}
```

#### 4.2 Streak System
- Track consecutive active days
- Streak multiplier for points
- Weekly streak rewards

#### 4.3 Achievements
- Milestone celebrations (100 posts, 1000 kg)
- Animated badge unlocks
- Share achievements on social

---

### Priority 5: Social Features

#### 5.1 Comments & Reactions
- Emoji reactions (like Instagram)
- Threaded comments
- @mentions
- #hashtag discovery

#### 5.2 Follow System
- Follow other cleaners
- "Following" feed filter
- Suggested users to follow

---

### Priority 6: Monetization

#### 6.1 Tipping Improvements
- Quick tip amounts (₹10, ₹50, ₹100) ✅ Implemented
- Custom amounts ✅ Implemented
- Tip leaderboard
- "Top supporter" badge

#### 6.2 Premium Features (Optional)
- Ad-free experience
- Profile themes
- Exclusive badges

---

### Priority 7: Technical Improvements

#### 7.1 Performance
- Image lazy loading with caching
- View recycling
- Memory optimization

#### 7.2 Offline Support
- Queue posts for upload
- Cached feed content
- Background sync

#### 7.3 Security
- Biometric authentication
- Data encryption
- Secure keychain storage

---

## Implementation Priority Matrix

| Feature | Impact | Effort | Priority |
|---------|--------|--------|----------|
| Unit Tests | High | Medium | P0 |
| Image Caching | High | Low | P0 |
| Input Validation | High | Low | P0 |
| Razorpay Integration | High | Medium | P1 |
| Accessibility | High | Medium | P1 |
| Hindi Localization | High | Medium | P1 |
| WhatsApp Sharing | High | Low | P1 |
| Daily Challenges | Medium | Medium | P2 |
| Streak System | Medium | Low | P2 |
| Follow System | Medium | High | P3 |

---

## Success Metrics

### User Engagement
- Daily Active Users (DAU)
- Posts per user per week
- Event attendance rate
- Tip conversion rate

### Environmental Impact
- Total waste collected (kg)
- Number of cleanups
- Geographic coverage
- Active communities

### Business Metrics
- Payment success rate
- Company onboarding rate
- User retention (Day 1, 7, 30)

---

## Next Steps

1. **Immediate**: Add unit tests and image caching
2. **This Week**: Input validation and accessibility
3. **This Month**: Razorpay integration and Hindi localization
4. **Next Month**: Backend integration planning
5. **Quarter**: Beta testing in select Indian cities
