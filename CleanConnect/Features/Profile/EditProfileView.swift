import SwiftUI
import PhotosUI

struct EditProfileView: View {
    let profile: Profile
    var isFirstRun = false
    @Environment(Session.self) private var session
    @Environment(LocationService.self) private var location
    @Environment(\.dismiss) private var dismiss
    @State private var edits: ProfileEdits
    @State private var photoItem: PhotosPickerItem?
    @State private var saving = false

    init(profile: Profile, isFirstRun: Bool = false) {
        self.profile = profile
        self.isFirstRun = isFirstRun
        _edits = State(initialValue: ProfileEdits(
            name: profile.name, bio: profile.bio, city: profile.city, state: profile.state,
            upiId: profile.upiId ?? "", supportURL: profile.supportURL ?? "", instagram: profile.instagram ?? "", newPhoto: nil))
    }

    private var upiInvalid: Bool { !edits.upiId.trimmed.isEmpty && !UPI.isValid(edits.upiId) }
    private var linkInvalid: Bool { !edits.supportURL.trimmed.isEmpty && SupportLink.valid(edits.supportURL) == nil }
    private var canSave: Bool { edits.name.trimmed.count >= 2 && !upiInvalid && !linkInvalid && !saving }

    var body: some View {
        Form {
            if isFirstRun {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome to the squad! 🎉").font(.ccTitle3).foregroundStyle(Color.ccInk)
                        Text("Tell us your name and city so you show up on your city's leaderboard.")
                            .font(.cc(.subheadline)).foregroundStyle(Color.ccInk2)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            if let newPhoto = edits.newPhoto {
                                Image(uiImage: newPhoto).resizable().scaledToFill().frame(width: 96, height: 96).clipShape(Circle())
                            } else {
                                Avatar(url: profile.photoURL, name: edits.name, size: 96)
                            }
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                                .frame(width: 32, height: 32).background(Color.ccGreen, in: Circle())
                                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("About you") {
                TextField("Your name", text: $edits.name).textContentType(.name)
                TextField("Short bio (optional)", text: $edits.bio, axis: .vertical).lineLimit(1...3)
            }

            Section {
                TextField("City", text: $edits.city).textContentType(.addressCity)
                Picker("State", selection: $edits.state) {
                    Text("Select").tag("")
                    ForEach(IndianStates.all, id: \.self) { Text($0).tag($0) }
                    if !edits.state.isEmpty && !IndianStates.all.contains(edits.state) { Text(edits.state).tag(edits.state) }
                }
                if location.place != nil {
                    Button {
                        if let place = location.place {
                            edits.city = place.city
                            edits.state = place.state
                        }
                    } label: { Label("Use my current location", systemImage: "location.fill") }
                }
            } header: {
                Text("Your city")
            } footer: {
                Text("Used for city and state leaderboards.")
            }

            Section {
                TextField("UPI ID, e.g. name@okaxis", text: $edits.upiId)
                    .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                if upiInvalid {
                    Text("That doesn't look like a valid UPI ID.").font(.caption).foregroundStyle(Color.ccDirty)
                }
                TextField("Fundraiser or website link (optional)", text: $edits.supportURL)
                    .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                if linkInvalid {
                    Text("Enter a valid https:// link.").font(.caption).foregroundStyle(Color.ccDirty)
                }
                TextField("Instagram handle (optional)", text: $edits.instagram)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
            } header: {
                Text("Let people support you")
            } footer: {
                Text("Your UPI ID is shown on your profile so people can thank you for cleanups through their own UPI app. 100% goes to you. CleanConnect never handles money or takes a cut. Leave blank to hide.")
            }
        }
        .navigationTitle(isFirstRun ? "Set up your profile" : "Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(isFirstRun ? "Skip" : "Cancel") { dismiss() }.disabled(saving)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(!canSave).fontWeight(.bold)
            }
        }
        .overlay { if saving { ProgressView().controlSize(.large) } }
        .interactiveDismissDisabled(saving)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    edits.newPhoto = image.resized(maxDimension: 800)
                }
            }
        }
        .task {
            if isFirstRun, edits.city.isEmpty, let place = location.place {
                edits.city = place.city
                edits.state = place.state
            }
        }
    }

    private func save() {
        saving = true
        Task {
            do {
                try await ProfileAPI.update(profile.id, edits: edits)
                session.show(String(localized: "Profile saved"))
                dismiss()
            } catch {
                session.show(error: error)
            }
            saving = false
        }
    }
}

enum IndianStates {
    static let all = [
        "Andaman and Nicobar Islands", "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chandigarh",
        "Chhattisgarh", "Dadra and Nagar Haveli and Daman and Diu", "Delhi", "Goa", "Gujarat", "Haryana",
        "Himachal Pradesh", "Jammu and Kashmir", "Jharkhand", "Karnataka", "Kerala", "Ladakh", "Lakshadweep",
        "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Puducherry",
        "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand",
        "West Bengal",
    ]
}
