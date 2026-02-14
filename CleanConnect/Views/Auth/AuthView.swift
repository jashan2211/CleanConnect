// AuthView.swift
// Authentication screen for CleanConnect

import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var authService: AuthenticationService
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Background gradient - Indian flag colors
            LinearGradient(
                colors: [
                    Color(hex: "FF9933").opacity(0.3), // Saffron
                    Color.white,
                    Color(hex: "138808").opacity(0.3)  // Green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "22C55E"), Color(hex: "16A34A")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("CleanConnect")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Join the movement for a cleaner India")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Auth buttons
                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = authService.generateNonce()
                    } onCompletion: { result in
                        handleAppleSignIn(result: result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)

                    // Sign in with Google
                    Button(action: signInWithGoogle) {
                        HStack(spacing: 12) {
                            // Google "G" logo
                            Text("G")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(
                                    LinearGradient(
                                        colors: [.red, .yellow, .green, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(4)
                            Text("Sign in with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 24)

                // Terms
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Link("Terms of Service and Privacy Policy",
                         destination: URL(string: "https://thebighead.ca/CleanConnect/terms")!)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 32)
            }

            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        isLoading = true
        Task {
            do {
                try await authService.handleAppleSignIn(result: result)
                await authManager.checkAuthStatus()
            } catch AuthenticationError.cancelled {
                // User cancelled, no error needed
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    private func signInWithGoogle() {
        isLoading = true
        Task {
            do {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController else {
                    throw AuthenticationError.configurationError
                }
                try await authService.signInWithGoogle(presenting: rootViewController)
                await authManager.checkAuthStatus()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AuthenticationService.shared)
}
