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
        }
    }

    private func saveProfile() {
        isSaving = true
        Task {
            do {
                try await userState.updateProfile(
                    displayName: displayName,
                    bio: bio.isEmpty ? nil : bio,
                    state: selectedState.isEmpty ? nil : selectedState,
                    district: selectedDistrict.isEmpty ? nil : selectedDistrict
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
