// EditProfileView.swift
// Edit user profile form

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userState: UserState

    @State private var displayName = ""
    @State private var bio = ""
    @State private var selectedState = ""
    @State private var selectedDistrict = ""
    @State private var upiId = ""
    @State private var paypalURL = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Display Name", text: $displayName)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Location") {
                    Picker("State", selection: $selectedState) {
                        Text("Select State").tag("")
                        ForEach(IndianStates.all, id: \.self) { state in
                            Text(state).tag(state)
                        }
                    }
                    .onChange(of: selectedState) { _, _ in
                        selectedDistrict = ""
                    }

                    Picker("District", selection: $selectedDistrict) {
                        Text("Select District").tag("")
                        ForEach(IndianStates.districts(for: selectedState), id: \.self) { district in
                            Text(district).tag(district)
                        }
                    }
                    .disabled(selectedState.isEmpty)
                }

                Section {
                    TextField("UPI ID (e.g. you@okhdfcbank)", text: $upiId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                    TextField("PayPal link (https://paypal.me/...)", text: $paypalURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("Receive tips")
                } footer: {
                    Text("Tips go directly to your UPI or PayPal — CleanConnect never touches the money.")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(displayName.isEmpty || isSaving)
                }
            }
            .onAppear {
                loadCurrentValues()
            }
        }
    }

    private func loadCurrentValues() {
        if let user = userState.currentUser {
            displayName = user.displayName
            bio = user.bio ?? ""
            selectedState = user.state ?? ""
            selectedDistrict = user.district ?? ""
            upiId = user.upiId ?? ""
            paypalURL = user.paypalURL ?? ""
        }
    }

    private func saveProfile() {
        isSaving = true
        let trimmedUPI = upiId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPayPal = paypalURL.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await userState.updateProfile(
                    displayName: displayName,
                    bio: bio.isEmpty ? nil : bio,
                    state: selectedState.isEmpty ? nil : selectedState,
                    district: selectedDistrict.isEmpty ? nil : selectedDistrict,
                    upiId: trimmedUPI.isEmpty ? nil : trimmedUPI,
                    paypalURL: trimmedPayPal.isEmpty ? nil : trimmedPayPal,
                    clearUpiId: trimmedUPI.isEmpty,
                    clearPaypalURL: trimmedPayPal.isEmpty
                )
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}
