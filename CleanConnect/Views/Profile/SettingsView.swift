// SettingsView.swift
// App settings view

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    NavigationLink("Edit Profile") {
                        EditProfileView()
                    }
                    NavigationLink("Notifications") {
                        Text("Notifications Settings")
                    }
                    NavigationLink("Privacy") {
                        Text("Privacy Settings")
                    }
                }

                Section("Preferences") {
                    NavigationLink("Language") {
                        Text("Language Settings")
                    }
                    NavigationLink("Location") {
                        Text("Location Settings")
                    }
                }

                Section("Support") {
                    NavigationLink("Help Center") {
                        Text("Help Center")
                    }
                    NavigationLink("Terms of Service") {
                        Text("Terms of Service")
                    }
                    NavigationLink("Privacy Policy") {
                        Text("Privacy Policy")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task {
                            try? await authManager.signOut()
                            dismiss()
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
