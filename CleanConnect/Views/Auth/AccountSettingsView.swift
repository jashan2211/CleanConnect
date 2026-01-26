// AccountSettingsView.swift
// Account management with required account deletion - 2026 Best Practices

import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirmation = false
    @State private var showReauthentication = false
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        List {
            // Account Info Section
            Section {
                if let user = authService.currentUser {
                    HStack(spacing: 16) {
                        // Profile image
                        AsyncImage(url: URL(string: user.photoURL ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName ?? "User")
                                .font(.headline)

                            if let email = user.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: providerIcon(for: user.provider))
                                    .font(.caption)
                                Text("Signed in with \(providerName(for: user.provider))")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            // Security Section
            Section("Security") {
                NavigationLink {
                    Text("Connected Accounts")
                } label: {
                    Label("Connected Accounts", systemImage: "link")
                }

                NavigationLink {
                    Text("Privacy Settings")
                } label: {
                    Label("Privacy", systemImage: "hand.raised.fill")
                }
            }

            // Data Section
            Section {
                NavigationLink {
                    Text("Download Your Data")
                } label: {
                    Label("Download My Data", systemImage: "arrow.down.doc.fill")
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Account", systemImage: "trash.fill")
                        .foregroundColor(.red)
                }
            } header: {
                Text("Your Data")
            } footer: {
                Text("Deleting your account will permanently remove all your data including posts, comments, and profile information. This action cannot be undone.")
                    .font(.caption)
            }

            // Sign Out Section
            Section {
                Button(role: .destructive) {
                    Task {
                        await signOut()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Deleting account...")
                            .font(.headline)
                    }
                    .padding(32)
                    .background(.regularMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }

    // MARK: - Actions

    private func signOut() async {
        await authService.signOut()
        try? await authManager.signOut()
        dismiss()
    }

    private func deleteAccount() {
        isDeleting = true

        Task {
            do {
                try await authService.deleteAccount()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isDeleting = false
        }
    }

    // MARK: - Helpers

    private func providerIcon(for provider: AuthProvider) -> String {
        switch provider {
        case .apple: return "apple.logo"
        case .google: return "g.circle.fill"
        case .local: return "person.fill"
        }
    }

    private func providerName(for provider: AuthProvider) -> String {
        switch provider {
        case .apple: return "Apple"
        case .google: return "Google"
        case .local: return "Guest"
        }
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView()
            .environmentObject(AuthManager.shared)
    }
}
