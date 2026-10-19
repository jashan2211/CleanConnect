import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import GoogleSignIn

/// Why we're asking someone to sign in. Shown as the sheet's subtitle.
struct AuthPrompt: Identifiable {
    let id = UUID()
    let reason: LocalizedStringKey
}

/// A celebratory moment after an action (points earned, cleanup done).
struct Celebration: Identifiable, Equatable {
    let id = UUID()
    let title: LocalizedStringKey
    let points: Int
    let icon: String

    static func == (lhs: Celebration, rhs: Celebration) -> Bool { lhs.id == rhs.id }
}

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    var icon: String = "checkmark.circle.fill"
    var isError = false
}

@Observable
@MainActor
final class Session {
    enum Phase { case loading, ready }

    var phase: Phase = .loading
    private(set) var uid: String?
    private(set) var profile: Profile?
    private(set) var blocked: Set<String> = []
    var authPrompt: AuthPrompt?
    var celebration: Celebration?
    var toast: Toast?
    /// Set after first sign-in so the app can ask for name and city.
    var needsProfileSetup = false

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var profileTask: Task<Void, Never>?
    private var privateListener: ListenerRegistration?
    private var currentNonce: String?
    private var started = false
    weak var location: LocationService?

    var isSignedIn: Bool { uid != nil }
    var providerIsApple: Bool {
        Auth.auth().currentUser?.providerData.contains { $0.providerID == "apple.com" } ?? false
    }
    var email: String? { Auth.auth().currentUser?.email }

    func start(location: LocationService) {
        guard !started else { return }
        started = true
        self.location = location
        if AppConfig.isDemo {
            uid = DemoData.me.id
            profile = DemoData.me
            phase = .ready
            return
        }
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.userChanged(user) }
        }
    }

    private func userChanged(_ user: FirebaseAuth.User?) {
        profileTask?.cancel()
        privateListener?.remove()
        guard let user else {
            uid = nil
            profile = nil
            blocked = []
            phase = .ready
            return
        }
        uid = user.uid
        profileTask = Task { [weak self] in
            for await profile in ProfileAPI.profile(user.uid) {
                guard let self else { return }
                if let profile { self.profile = profile }
                self.phase = .ready
            }
        }
        privateListener = DB.userPrivate.document(user.uid).addSnapshotListener { [weak self] snap, _ in
            let list = snap?.data()?["blocked"] as? [String] ?? []
            Task { @MainActor in self?.blocked = Set(list) }
        }
        // Don't keep the launch screen waiting on the network.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            self?.phase = .ready
        }
    }

    // MARK: Gating

    /// Returns true when signed in; otherwise asks the person to sign in.
    @discardableResult
    func gate(_ reason: LocalizedStringKey) -> Bool {
        if isSignedIn, profile != nil { return true }
        if isSignedIn { toast = Toast(message: String(localized: "Still setting up your profile — try again in a moment."), icon: "hourglass"); return false }
        Haptics.soft()
        authPrompt = AuthPrompt(reason: reason)
        return false
    }

    // MARK: Apple

    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func completeApple(_ result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            throw error
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                throw BackendError.message(String(localized: "Apple sign-in failed. Please try again."))
            }
            let firebaseCredential = OAuthProvider.appleCredential(withIDToken: token, rawNonce: nonce, fullName: credential.fullName)
            let result = try await Auth.auth().signIn(with: firebaseCredential)
            let name = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
            if !name.isEmpty, result.user.displayName == nil {
                let change = result.user.createProfileChangeRequest()
                change.displayName = name
                try? await change.commitChanges()
            }
            try await finishSignIn(user: result.user, name: name.isEmpty ? result.user.displayName : name)
        }
    }

    // MARK: Google

    func signInWithGoogle() async throws {
        guard let presenter = UIApplication.shared.topViewController else { return }
        guard let clientID = Auth.auth().app?.options.clientID else {
            throw BackendError.message(String(localized: "Google sign-in isn't configured."))
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        let result: GIDSignInResult
        do {
            result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        } catch {
            if (error as NSError).code == GIDSignInError.canceled.rawValue { return }
            throw error
        }
        guard let idToken = result.user.idToken?.tokenString else {
            throw BackendError.message(String(localized: "Google sign-in failed. Please try again."))
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        let authResult = try await Auth.auth().signIn(with: credential)
        try await finishSignIn(user: authResult.user, name: authResult.user.displayName)
    }

    private func finishSignIn(user: FirebaseAuth.User, name: String?) async throws {
        let created = try await ProfileAPI.createIfNeeded(uid: user.uid, name: name, photoURL: user.photoURL?.absoluteString,
                                                        place: location?.place)
        authPrompt = nil
        if created { needsProfileSetup = true }
        Haptics.success()
    }

    // MARK: Sign out / delete

    func signOut() {
        if AppConfig.isDemo { return }
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    /// Deletes the account and the person's content (server-side), revoking Apple tokens first.
    func deleteAccount() async throws {
        if AppConfig.isDemo { return }
        guard Auth.auth().currentUser != nil else { throw BackendError.notSignedIn }
        if providerIsApple {
            if let code = try? await AppleReauth.authorizationCode() {
                try? await Auth.auth().revokeToken(withAuthorizationCode: code)
            }
        }
        _ = try await Functions.functions(region: AppConfig.functionsRegion).httpsCallable("deleteAccount").call()
        signOut()
    }

    // MARK: Blocking

    func block(_ otherId: String) async {
        guard let uid, otherId != uid else { return }
        blocked.insert(otherId)
        if AppConfig.isDemo { return }
        try? await DB.userPrivate.document(uid).setData(["blocked": FieldValue.arrayUnion([otherId])], merge: true)
        toast = Toast(message: String(localized: "Blocked. You won't see their posts anymore."), icon: "hand.raised.fill")
    }

    func unblock(_ otherId: String) async {
        guard let uid else { return }
        blocked.remove(otherId)
        if AppConfig.isDemo { return }
        try? await DB.userPrivate.document(uid).setData(["blocked": FieldValue.arrayRemove([otherId])], merge: true)
    }

    func isBlocked(_ otherId: String?) -> Bool {
        guard let otherId else { return false }
        return blocked.contains(otherId)
    }

    // MARK: Feedback

    func celebrate(_ title: LocalizedStringKey, points: Int, icon: String = "sparkles") {
        Haptics.success()
        celebration = Celebration(title: title, points: points, icon: icon)
    }

    func show(_ message: String, icon: String = "checkmark.circle.fill") {
        toast = Toast(message: message, icon: icon)
    }

    func show(error: Error) {
        Haptics.warning()
        toast = Toast(message: error.localizedDescription, icon: "exclamationmark.triangle.fill", isError: true)
    }

    // MARK: Nonce helpers

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

/// Re-runs Sign in with Apple to obtain a fresh authorization code for token revocation.
@MainActor
final class AppleReauth: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<String, Error>?
    private static var current: AppleReauth?

    static func authorizationCode() async throws -> String {
        let helper = AppleReauth()
        current = helper
        defer { current = nil }
        return try await withCheckedThrowingContinuation { continuation in
            helper.continuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = []
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = helper
            controller.presentationContextProvider = helper
            controller.performRequests()
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        let code = (authorization.credential as? ASAuthorizationAppleIDCredential)?.authorizationCode
            .flatMap { String(data: $0, encoding: .utf8) }
        Task { @MainActor in
            if let code { self.continuation?.resume(returning: code) } else { self.continuation?.resume(throwing: BackendError.notSignedIn) }
            self.continuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            self.continuation?.resume(throwing: error)
            self.continuation = nil
        }
    }

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? ASPresentationAnchor()
        }
    }
}
