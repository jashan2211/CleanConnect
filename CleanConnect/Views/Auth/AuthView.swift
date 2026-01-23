// AuthView.swift
// Authentication screen for CleanConnect (Local mode)

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showNameEntry = false
    @State private var userName = ""
    @State private var selectedState = ""
    @State private var selectedDistrict = ""

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

            if showNameEntry {
                nameEntryView
            } else {
                welcomeView
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

    private var welcomeView: some View {
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
                // Get Started
                Button(action: { showNameEntry = true }) {
                    HStack {
                        Image(systemName: "person.fill.badge.plus")
                            .font(.title2)
                        Text("Get Started")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "22C55E"), Color(hex: "16A34A")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading)

                // Quick Start (Anonymous)
                Button(action: quickStart) {
                    HStack {
                        Image(systemName: "person.fill.questionmark")
                            .font(.title2)
                        Text("Quick Start (Guest)")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.secondary)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 24)

            // Terms
            VStack(spacing: 8) {
                Text("By continuing, you agree to our")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 32)
        }
    }

    private var nameEntryView: some View {
        VStack(spacing: 24) {
            // Back button
            HStack {
                Button(action: { showNameEntry = false }) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding()

            Spacer()

            // Form
            VStack(spacing: 20) {
                Text("Create Your Profile")
                    .font(.title2.weight(.bold))

                VStack(spacing: 16) {
                    TextField("Your Name", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)

                    Picker("Select State", selection: $selectedState) {
                        Text("Select State").tag("")
                        ForEach(IndianStates.all, id: \.self) { state in
                            Text(state).tag(state)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    if !selectedState.isEmpty {
                        Picker("Select District", selection: $selectedDistrict) {
                            Text("Select District").tag("")
                            ForEach(IndianStates.districts(for: selectedState), id: \.self) { district in
                                Text(district).tag(district)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 24)

                Button(action: signInWithName) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userName.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(userName.isEmpty || isLoading)
                .padding(.horizontal, 24)
            }

            Spacer()
            Spacer()
        }
    }

    private func quickStart() {
        isLoading = true
        Task {
            do {
                try await authManager.signInAsGuest()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    private func signInWithName() {
        guard !userName.isEmpty else { return }
        isLoading = true
        Task {
            do {
                try await authManager.signInWithName(
                    userName,
                    state: selectedState.isEmpty ? nil : selectedState,
                    district: selectedDistrict.isEmpty ? nil : selectedDistrict
                )
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
}
