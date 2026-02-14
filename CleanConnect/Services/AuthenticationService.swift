// AuthenticationService.swift
// Production Authentication with Firebase - 2026 Best Practices
// Supports: Apple Sign-In, Google Sign-In, Anonymous Auth

import Foundation
import SwiftUI
import UIKit
import AuthenticationServices
import CryptoKit

// MARK: - Firebase imports
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

/// Production-ready authentication service
/// Handles Apple Sign-In, Google Sign-In with Firebase backend
@MainActor
final class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()

    // MARK: - Published State

    @Published private(set) var currentUser: AuthenticatedUser?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = true
    @Published private(set) var authState: AuthState = .unknown

    // MARK: - Private Properties

    private let dataManager = LocalDataManager.shared
    private var appleCredentialObserver: NSObjectProtocol?
    private var currentNonce: String?

    // MARK: - Initialization

    private init() {
        setupAppleCredentialRevocationObserver()
        Task {
            await checkAuthenticationState()
        }
    }

    deinit {
        if let observer = appleCredentialObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Auth State Management

    private func checkAuthenticationState() async {
        // Check for existing Firebase auth session
        // For now, check local storage
        if let userId = UserDefaults.standard.string(forKey: StorageKeys.isAuthenticated) {
            // Verify Apple credential hasn't been revoked
            if let appleUserId = try? await KeychainManager.shared.loadString(forKey: KeychainKeys.appleUserIdentifier) {
                let state = await checkAppleCredentialState(userId: appleUserId)
                if state != .authorized {
                    await signOut()
                    isLoading = false
                    return
                }
            }

            currentUser = AuthenticatedUser(
                id: userId,
                provider: .local
            )
            isAuthenticated = true
            authState = .authenticated
        } else {
            authState = .unauthenticated
        }
        isLoading = false
    }

    // MARK: - Apple Sign-In

    /// Generates a secure nonce for Apple Sign-In
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    /// Handle Apple Sign-In authorization result
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthenticationError.invalidCredential
            }

            guard currentNonce != nil else {
                throw AuthenticationError.invalidNonce
            }

            guard let appleIDToken = appleCredential.identityToken,
                  let _ = String(data: appleIDToken, encoding: .utf8) else {
                throw AuthenticationError.invalidCredential
            }

            // Store Apple user identifier for credential state checking
            try await KeychainManager.shared.save(appleCredential.user, forKey: KeychainKeys.appleUserIdentifier)

            // Extract user info (only available on first sign-in)
            let displayName = extractDisplayName(from: appleCredential)
            let email = appleCredential.email

            // === FIREBASE INTEGRATION ===
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AuthenticationError.invalidCredential
            }

            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: currentNonce!,
                fullName: appleCredential.fullName
            )
            let authResult = try await Auth.auth().signIn(with: firebaseCredential)
            let firebaseUser = authResult.user

            let userId = firebaseUser.uid
            try await createOrUpdateUser(
                id: userId,
                displayName: displayName,
                email: email,
                photoURL: nil,
                provider: .apple
            )

            currentNonce = nil

        case .failure(let error):
            currentNonce = nil
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                throw AuthenticationError.cancelled
            }
            throw AuthenticationError.appleSignInFailed(error.localizedDescription)
        }
    }

    // MARK: - Google Sign-In

    /// Handle Google Sign-In
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        // === FIREBASE + GOOGLE SIGN-IN INTEGRATION ===
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthenticationError.configurationError
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthenticationError.invalidCredential
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let user = authResult.user

        try await createOrUpdateUser(
            id: user.uid,
            displayName: user.displayName,
            email: user.email,
            photoURL: user.photoURL?.absoluteString,
            provider: .google
        )
    }

    // MARK: - User Management

    private func createOrUpdateUser(
        id: String,
        displayName: String?,
        email: String?,
        photoURL: String?,
        provider: AuthProvider
    ) async throws {
        var userToSave: User

        // Check if user exists locally
        if let existingUser = try? dataManager.load(User.self, from: "\(id).json", in: "users") {
            var updated = existingUser
            updated.lastActive = Date()
            if let name = displayName, !name.isEmpty, existingUser.displayName.isEmpty {
                updated.displayName = name
            }
            if let photo = photoURL, existingUser.photoURL == nil {
                updated.photoURL = photo
            }
            userToSave = updated
        } else {
            // Create new user
            userToSave = User(
                id: id,
                displayName: displayName ?? "User",
                email: email,
                photoURL: photoURL,
                bio: nil,
                state: nil,
                district: nil,
                pincode: nil,
                totalPoints: 0,
                totalPosts: 0,
                totalWasteKg: 0,
                totalEventsOrganized: 0,
                totalEventsAttended: 0,
                tipsReceived: 0,
                tipsGiven: 0,
                totalVolunteerHours: 0,
                totalSuppliesContributed: 0,
                totalDonationsAmount: 0,
                totalCO2Saved: 0,
                longestStreak: 0,
                currentStreak: 0,
                totalAreasImpacted: 0,
                videosVerified: 0,
                socialLinks: nil,
                level: 1,
                levelName: "Eco Scout",
                karmaScore: 0,
                followersCount: 0,
                followingCount: 0,
                badges: [],
                createdAt: Date(),
                lastActive: Date(),
                isAnonymous: false,
                verified: provider != .local,
                stripeAccountId: nil,
                stripeOnboardingComplete: nil
            )
        }

        // Save locally
        try dataManager.save(userToSave, to: "\(id).json", in: "users")

        // Save to Firestore (creates document if doesn't exist, updates if it does)
        try await FirestoreService.shared.saveUser(userToSave)

        // Update auth state
        UserDefaults.standard.set(id, forKey: StorageKeys.isAuthenticated)

        currentUser = AuthenticatedUser(
            id: id,
            email: email,
            displayName: displayName,
            photoURL: photoURL,
            provider: provider
        )
        isAuthenticated = true
        authState = .authenticated

        // Load into UserState
        await UserState.shared.loadUserData(userId: id)
    }

    // MARK: - Sign Out

    func signOut() async {
        // === FIREBASE SIGN OUT ===
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()

        // Clear Keychain
        try? await KeychainManager.shared.delete(forKey: KeychainKeys.appleUserIdentifier)
        try? await KeychainManager.shared.delete(forKey: KeychainKeys.authToken)

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: StorageKeys.isAuthenticated)
        dataManager.removeUserDefault(forKey: StorageKeys.currentUser)

        // Update state
        currentUser = nil
        isAuthenticated = false
        authState = .unauthenticated

        UserState.shared.clearUserData()
    }

    // MARK: - Account Deletion (App Store Requirement)

    func deleteAccount() async throws {
        guard let userId = currentUser?.id else {
            throw AuthenticationError.userNotFound
        }

        // === FIREBASE ACCOUNT DELETION ===
        guard let firebaseUser = Auth.auth().currentUser else {
            throw AuthenticationError.userNotFound
        }

        // Delete user data from Firestore
        let db = Firestore.firestore()
        try? await db.collection("users").document(userId).delete()

        // Delete user's posts
        let posts = try? await db.collection("posts").whereField("userId", isEqualTo: userId).getDocuments()
        for doc in posts?.documents ?? [] {
            try? await doc.reference.delete()
        }

        // Delete user's tips
        let tips = try? await db.collection("tips").whereField("senderId", isEqualTo: userId).getDocuments()
        for doc in tips?.documents ?? [] {
            try? await doc.reference.delete()
        }

        // Delete Firebase Auth account
        try await firebaseUser.delete()

        // Delete local data
        try? dataManager.delete(filename: "\(userId).json", from: "users")

        await signOut()
    }

    // MARK: - Apple Credential State Monitoring

    private func setupAppleCredentialRevocationObserver() {
        appleCredentialObserver = NotificationCenter.default.addObserver(
            forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.signOut()
            }
        }
    }

    private func checkAppleCredentialState(userId: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userId) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }

    // MARK: - Helpers

    private func extractDisplayName(from credential: ASAuthorizationAppleIDCredential) -> String? {
        guard let fullName = credential.fullName else { return nil }
        let components = [fullName.givenName, fullName.familyName].compactMap { $0 }
        return components.isEmpty ? nil : components.joined(separator: " ")
    }
}

// MARK: - Crypto Helpers for Apple Sign-In

private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
        fatalError("Unable to generate nonce: \(errorCode)")
    }
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    return String(randomBytes.map { byte in charset[Int(byte) % charset.count] })
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.compactMap { String(format: "%02x", $0) }.joined()
}

// MARK: - Supporting Types

struct AuthenticatedUser: Equatable {
    let id: String
    var email: String?
    var displayName: String?
    var photoURL: String?
    let provider: AuthProvider

    init(id: String, email: String? = nil, displayName: String? = nil, photoURL: String? = nil, provider: AuthProvider) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.provider = provider
    }
}

enum AuthProvider: String, Codable {
    case apple
    case google
    case local
}

enum AuthState {
    case unknown
    case authenticated
    case unauthenticated
}

enum AuthenticationError: LocalizedError {
    case invalidCredential
    case invalidNonce
    case userNotFound
    case configurationError
    case cancelled
    case appleSignInFailed(String)
    case googleSignInFailed(String)
    case networkError
    case accountDeletionFailed

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid credentials provided"
        case .invalidNonce:
            return "Security validation failed. Please try again."
        case .userNotFound:
            return "User account not found"
        case .configurationError:
            return "Authentication not configured. Please add Firebase SDK."
        case .cancelled:
            return "Sign in was cancelled"
        case .appleSignInFailed(let message):
            return "Apple Sign-In failed: \(message)"
        case .googleSignInFailed(let message):
            return "Google Sign-In failed: \(message)"
        case .networkError:
            return "Network error. Please check your connection."
        case .accountDeletionFailed:
            return "Failed to delete account. Please try again."
        }
    }
}
