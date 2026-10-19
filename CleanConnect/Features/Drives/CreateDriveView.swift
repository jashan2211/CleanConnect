import SwiftUI
import PhotosUI

struct CreateDriveView: View {
    var spot: Spot?
    @Environment(Session.self) private var session
    @Environment(LocationService.self) private var location
    @Environment(\.dismiss) private var dismiss
    @State private var draft = NewDrive()
    @State private var showPicker = false
    @State private var coverItem: PhotosPickerItem?
    @State private var submitting = false
    @State private var safetyAck = false
    @State private var createdId: String?

    private let durations = [60, 90, 120, 180, 240]

    private var canSubmit: Bool {
        draft.title.trimmed.count >= 3 && draft.coordinate != nil && draft.startsAt > .now && safetyAck && !submitting
            && (draft.upiId.trimmed.isEmpty || UPI.isValid(draft.upiId))
            && (draft.whatsappLink.trimmed.isEmpty || WhatsApp.validGroupLink(draft.whatsappLink) != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name it, e.g. Sunday Lake Clean-up", text: $draft.title)
                        .font(.cc(.headline, weight: .semibold))
                    TextField("What's the plan? Meeting point details, who it's for…", text: $draft.about, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("The drive")
                }

                Section("When") {
                    DatePicker("Starts", selection: $draft.startsAt, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                    Picker("Duration", selection: $draft.durationMinutes) {
                        ForEach(durations, id: \.self) { minutes in
                            Text(minutes < 60 ? "\(minutes) min" : (minutes % 60 == 0 ? "\(minutes / 60) hr" : "\(Double(minutes) / 60, specifier: "%.1f") hr"))
                                .tag(minutes)
                        }
                    }
                }

                Section {
                    Button {
                        showPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse").foregroundStyle(Color.ccDirty)
                            VStack(alignment: .leading) {
                                Text(draft.place?.label.nilIfEmpty ?? (draft.coordinate == nil ? String(localized: "Choose meeting point") : String(localized: "Pinned on map")))
                                    .foregroundStyle(Color.ccInk)
                                if let city = draft.place?.cityLabel.nilIfEmpty {
                                    Text(city).font(.caption).foregroundStyle(Color.ccInk2)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.ccInk2)
                        }
                    }
                    TextField("Landmark, e.g. Near main gate", text: $draft.address)
                } header: {
                    Text("Where")
                } footer: {
                    if let spot { Text("Linked to the \(Text(spot.category.title)) report at \(spot.placeLabel).") }
                }

                Section("Bring along") { itemPicker($draft.bring, tint: .ccBlue) }
                Section("You'll provide") { itemPicker($draft.providing, tint: .ccGreen) }

                Section {
                    Stepper(value: $draft.capacity, in: 0...500, step: 5) {
                        Text(draft.capacity == 0 ? String(localized: "No volunteer limit") : String(localized: "Up to \(draft.capacity) volunteers"))
                    }
                    PhotosPicker(selection: $coverItem, matching: .images) {
                        HStack {
                            Label(draft.cover == nil ? "Add a cover photo" : "Change cover photo", systemImage: "photo")
                            Spacer()
                            if let cover = draft.cover {
                                Image(uiImage: cover).resizable().scaledToFill().frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                } header: {
                    Text("Extras")
                }

                Section {
                    TextField("WhatsApp group invite link (optional)", text: $draft.whatsappLink)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Your UPI ID for supplies (optional)", text: $draft.upiId)
                        .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                    if !draft.upiId.trimmed.isEmpty && !UPI.isValid(draft.upiId) {
                        Text("That doesn't look like a UPI ID (e.g. name@okaxis).").font(.caption).foregroundStyle(Color.ccDirty)
                    }
                } header: {
                    Text("Coordination")
                } footer: {
                    Text("Volunteers can chip in for gloves and bags directly through their UPI app. 100% goes to you, and CleanConnect never handles the money.")
                }

                Section {
                    Toggle(isOn: $safetyAck) {
                        Text("I'll brief volunteers on safety and make sure kids are supervised.")
                            .font(.cc(.subheadline))
                    }
                    .tint(.ccGreen)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New cleanup drive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(submitting) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publish") { submit() }.disabled(!canSubmit).fontWeight(.bold)
                }
            }
            .overlay { if submitting { ProgressView().controlSize(.large) } }
            .sheet(isPresented: $showPicker) {
                LocationPicker(coordinate: $draft.coordinate, place: $draft.place, title: "Meeting point")
            }
            .navigationDestination(item: $createdId) { id in
                DriveCreatedView(driveId: id, title: draft.title) { dismiss() }
            }
        }
        .interactiveDismissDisabled(submitting)
        .onChange(of: coverItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    draft.cover = image.resized(maxDimension: 1600)
                }
            }
        }
        .task {
            if let spot {
                draft.spotId = spot.id
                draft.coordinate = spot.coordinate
                draft.place = Place(locality: spot.locality, city: spot.city, state: spot.state)
                if draft.title.isEmpty { draft.title = String(localized: "Clean-up at \(spot.locality.nilIfEmpty ?? spot.city)") }
            } else if draft.coordinate == nil, let c = location.coordinate {
                draft.coordinate = c
                draft.place = await location.reverseGeocode(c)
            }
            if draft.upiId.isEmpty, let upi = session.profile?.upiId { draft.upiId = upi }
        }
    }

    private func itemPicker(_ selection: Binding<Set<DriveItem>>, tint: Color) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(DriveItem.allCases) { item in
                Chip(title: item.title, icon: item.icon, isSelected: selection.wrappedValue.contains(item), tint: tint) {
                    if selection.wrappedValue.contains(item) { selection.wrappedValue.remove(item) } else { selection.wrappedValue.insert(item) }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func submit() {
        guard let profile = session.profile else { session.gate("Sign in to organise a cleanup drive."); return }
        submitting = true
        Task {
            do {
                if draft.place == nil, let c = draft.coordinate { draft.place = await location.reverseGeocode(c) }
                let id = try await DriveAPI.create(draft, by: profile)
                Haptics.success()
                createdId = id
            } catch {
                session.show(error: error)
            }
            submitting = false
        }
    }
}

struct DriveCreatedView: View {
    let driveId: String
    let title: String
    var onDone: () -> Void
    @State private var drive: Drive?

    var body: some View {
        ZStack {
            ConfettiView().ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    Circle().fill(Color.ccSaffronSoft).frame(width: 120, height: 120)
                    Image(systemName: "flag.checkered").font(.system(size: 48, weight: .bold)).foregroundStyle(Color.ccSaffron)
                }
                Text("Your drive is live!").font(.ccTitle).foregroundStyle(Color.ccInk)
                Text("+\(Points.hostDrive) Swachh Points").font(.ccNumber(18)).foregroundStyle(Color.ccGreen)
                Text("Now invite people. Drives shared on WhatsApp get many more volunteers.")
                    .font(.cc(.subheadline)).foregroundStyle(Color.ccInk2).multilineTextAlignment(.center)
                Spacer()
                if let drive {
                    ShareLink(item: String(localized: "🧹 Join my cleanup drive: \(drive.title)\n📅 \(Fmt.driveDate(drive.startsAt))\n📍 \(drive.placeLabel)\n🗺️ \(Directions.mapsLink(drive.coordinate))\n\nRSVP on CleanConnect: \(AppConfig.appStoreURL.absoluteString)")) {
                        Label("Invite on WhatsApp & more", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(.primary(.ccSaffron))
                }
                Button("Done", action: onDone).buttonStyle(.secondary(.ccInk2))
            }
            .padding(24)
            .readableWidth(520)
        }
        .background(Color.ccBackground)
        .navigationBarBackButtonHidden()
        .task {
            for await value in DriveAPI.drive(driveId) { drive = value }
        }
    }
}
