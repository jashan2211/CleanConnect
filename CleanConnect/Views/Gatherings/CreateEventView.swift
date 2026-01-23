// CreateEventView.swift
// Form for creating new community cleanup events

import SwiftUI
import PhotosUI

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var eventDate = Date().addingTimeInterval(86400 * 7) // 1 week from now
    @State private var duration = "2"
    @State private var selectedState = ""
    @State private var selectedDistrict = ""
    @State private var address = ""
    @State private var enableFundraising = false
    @State private var fundraisingGoal = ""
    @State private var whatsappLink = ""
    @State private var headerImage: PhotosPickerItem?
    @State private var headerImageData: Data?
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""

    var onEventCreated: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                // Basic info
                Section("Event Details") {
                    TextField("Event Title", text: $title)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Image
                Section("Cover Image") {
                    PhotosPicker(selection: $headerImage, matching: .images) {
                        if let data = headerImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(8)
                        } else {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                Text("Add Cover Image")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .onChange(of: headerImage) { _, newValue in
                        loadImage(from: newValue)
                    }
                }

                // Date and time
                Section("When") {
                    DatePicker("Event Date", selection: $eventDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])

                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("Hours", text: $duration)
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                            .textFieldStyle(.roundedBorder)
                        Text("hours")
                            .foregroundColor(.secondary)
                    }
                }

                // Location
                Section("Where") {
                    Picker("State", selection: $selectedState) {
                        Text("Select State").tag("")
                        ForEach(IndianStates.all, id: \.self) { state in
                            Text(state).tag(state)
                        }
                    }

                    Picker("District", selection: $selectedDistrict) {
                        Text("Select District").tag("")
                        ForEach(IndianStates.districts(for: selectedState), id: \.self) { district in
                            Text(district).tag(district)
                        }
                    }
                    .disabled(selectedState.isEmpty)

                    TextField("Address / Landmark", text: $address)
                }

                // Fundraising
                Section("Fundraising (Optional)") {
                    Toggle("Enable Fundraising", isOn: $enableFundraising)

                    if enableFundraising {
                        HStack {
                            Text("₹")
                            TextField("Goal Amount", text: $fundraisingGoal)
                                .keyboardType(.numberPad)
                        }
                    }
                }

                // WhatsApp
                Section("Communication") {
                    TextField("WhatsApp Group Link (Optional)", text: $whatsappLink)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { submitEvent() }
                        .disabled(!isFormValid || isSubmitting)
                        .fontWeight(.semibold)
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Creating event...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isFormValid: Bool {
        !title.isEmpty &&
        !selectedState.isEmpty &&
        !selectedDistrict.isEmpty &&
        eventDate > Date()
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                if case .success(let data) = result {
                    headerImageData = data
                }
            }
        }
    }

    private func submitEvent() {
        guard isFormValid else { return }

        isSubmitting = true

        Task {
            do {
                try await GatheringService.shared.createGathering(
                    title: title,
                    description: description,
                    eventDate: eventDate,
                    durationHours: Int(duration) ?? 2,
                    state: selectedState,
                    district: selectedDistrict,
                    address: address.isEmpty ? nil : address,
                    fundraisingGoal: enableFundraising ? Int(fundraisingGoal) : nil,
                    whatsappLink: whatsappLink.isEmpty ? nil : whatsappLink,
                    imageData: headerImageData
                )
                await MainActor.run {
                    isSubmitting = false
                    onEventCreated()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    CreateEventView(onEventCreated: {})
}
