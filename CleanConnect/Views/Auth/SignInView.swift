// SignInView.swift
// Production Sign-In View - 2026 Best Practices
// Supports Apple Sign-In, Google Sign-In

import SwiftUI
import UIKit
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.colorScheme) private var colorScheme

    @State private var isSigningIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentNonce: String?

    // Animation states
    @State private var logoScale: CGFloat = 0.5
    @State private var contentOpacity: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: geometry.size.height * 0.1)

                    // Hero Section
                    heroSection

                    Spacer(minLength: 40)

                    // Sign-In Buttons
                    signInButtons
                        .padding(.horizontal, 24)

                    Spacer(minLength: 24)

                    // Terms and Privacy
                    termsSection
                        .padding(.horizontal, 24)

                    Spacer(minLength: geometry.size.height * 0.05)
                }
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(backgroundGradient)
        .ignoresSafeArea()
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                logoScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                contentOpacity = 1
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Animated Logo
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(Color.green.opacity(0.25))
                    .frame(width: 110, height: 110)

                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(logoScale)

            VStack(spacing: 8) {
                Text("CleanConnect")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Join the movement for a cleaner India")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(contentOpacity)
        }
    }

    // MARK: - Sign-In Buttons

    private var signInButtons: some View {
        VStack(spacing: 16) {
            // Sign in with Apple (Required by App Store if offering other social logins)
            SignInWithAppleButton(
                onRequest: configureAppleRequest,
                onCompletion: handleAppleSignIn
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 54)
            .cornerRadius(12)
            .disabled(isSigningIn)

            // Sign in with Google
            googleSignInButton
                .disabled(isSigningIn)

            if isSigningIn {
                ProgressView()
                    .padding(.top, 8)
            }
        }
        .opacity(contentOpacity)
    }

    private var googleSignInButton: some View {
        Button(action: signInWithGoogle) {
            HStack(spacing: 12) {
                // Google "G" logo
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)

                    Text("G")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .yellow, .green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Sign in with Google")
                    .font(.system(size: 17, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(.systemBackground))
            .foregroundColor(.primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("By continuing, you agree to our")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Link("Terms of Service", destination: URL(string: "https://thebighead.ca/CleanConnect/terms")!)
                    .font(.caption.weight(.medium))
                Text("and")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Link("Privacy Policy", destination: URL(string: "https://thebighead.ca/CleanConnect/privacy")!)
                    .font(.caption.weight(.medium))
            }
        }
        .multilineTextAlignment(.center)
        .opacity(contentOpacity)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.green.opacity(0.05),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Apple Sign-In

    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = authService.generateNonce()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        isSigningIn = true

        Task {
            do {
                try await authService.handleAppleSignIn(result: result)
                // Auth state will update automatically
            } catch AuthenticationError.cancelled {
                // User cancelled, no error needed
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isSigningIn = false
        }
    }

    // MARK: - Google Sign-In

    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to present sign-in"
            showError = true
            return
        }

        isSigningIn = true

        Task {
            do {
                try await authService.signInWithGoogle(presenting: rootViewController)
            } catch AuthenticationError.cancelled {
                // User cancelled
            } catch AuthenticationError.configurationError {
                errorMessage = "Google Sign-In requires Firebase SDK. Please add the dependency."
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isSigningIn = false
        }
    }

}

// MARK: - Preview

#Preview {
    SignInView()
        .environmentObject(AuthManager.shared)
}
