// CreatePostView.swift
// Form for creating new cleanup posts

import SwiftUI
import PhotosUI
import CoreLocation

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var description = ""
    @State private var wasteCollected = ""
    @State private var duration = ""
    @State private var selectedState = ""
    @State private var selectedDistrict = ""
    @State private var beforeImage: PhotosPickerItem?
    @State private var afterImage: PhotosPickerItem?
    @State private var beforeImageData: Data?
    @State private var afterImageData: Data?
    @State private var videoProofURL = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""

    var onPostCreated: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Image pickers
                    imagePickersSection

                    // Video proof section
                    videoProofSection

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        TextField("Describe your cleanup effort...", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Stats section
                    statsSection

                    // Location section
                    locationSection

                    // Tips info
                    tipsInfoSection
                }
                .padding()
            }
            .navigationTitle("New Cleanup Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { submitPost() }
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
                        Text("Creating post...")
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

    private var imagePickersSection: some View {
        HStack(spacing: 16) {
            // Before image
            VStack(spacing: 8) {
                Text("Before")
                    .font(.subheadline.weight(.medium))
                PhotosPicker(selection: $beforeImage, matching: .images) {
                    imagePickerContent(imageData: beforeImageData)
                }
                .onChange(of: beforeImage) { _, newValue in
                    loadImage(from: newValue) { data in
                        beforeImageData = data
                    }
                }
            }

            // After image
            VStack(spacing: 8) {
                Text("After")
                    .font(.subheadline.weight(.medium))
                PhotosPicker(selection: $afterImage, matching: .images) {
                    imagePickerContent(imageData: afterImageData)
                }
                .onChange(of: afterImage) { _, newValue in
                    loadImage(from: newValue) { data in
                        afterImageData = data
                    }
                }
            }
        }
    }

    private func imagePickerContent(imageData: Data?) -> some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.title)
                    Text("Add Photo")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .frame(width: 150, height: 150)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .clipped()
    }

    private var videoProofSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Video Proof")
                    .font(.headline)
                Text("(Recommended)")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Text("Add a YouTube or Instagram link to verify your cleanup and earn +25 bonus points!")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "video.fill")
                    .foregroundColor(.ccSaffron)
                TextField("https://youtube.com/shorts/... or instagram.com/reel/...", text: $videoProofURL)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
            }

            if !videoProofURL.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                    Text("Video proof added - Your post will be verified!")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            // Verification benefits
            VStack(alignment: .leading, spacing: 6) {
                Label("Verified posts get more tips", systemImage: "indianrupeesign.circle.fill")
                Label("Appear higher in feed", systemImage: "arrow.up.circle.fill")
                Label("Blue verification badge", systemImage: "checkmark.seal.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 4)
        }
        .padding()
        .background(Color.ccSaffron.opacity(0.05))
        .cornerRadius(12)
    }

    private var tipsInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "indianrupeesign.circle.fill")
                    .foregroundColor(.ccTipGold)
                Text("Earn Tips from Community")
                    .font(.headline)
            }

            Text("Other users can tip you for your cleanup efforts. Verified posts with video proof receive 3x more tips on average!")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                VStack {
                    Text("5%")
                        .font(.title3.bold())
                        .foregroundColor(.ccSaffron)
                    Text("Platform Fee")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                VStack {
                    Text("95%")
                        .font(.title3.bold())
                        .foregroundColor(.green)
                    Text("You Receive")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
        .padding()
        .background(Color.ccTipGold.opacity(0.05))
        .cornerRadius(12)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cleanup Stats")
                .font(.headline)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Waste Collected (kg)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0.0", text: $wasteCollected)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration (minutes)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("30", text: $duration)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Location")
                    .font(.headline)
                Spacer()
                if locationManager.isLoading {
                    ProgressView()
                } else if locationManager.location != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            // State picker
            HStack {
                Text("State")
                    .foregroundColor(.secondary)
                Spacer()
                Picker("State", selection: $selectedState) {
                    Text("Select State").tag("")
                    ForEach(IndianStates.all, id: \.self) { state in
                        Text(state).tag(state)
                    }
                }
                .pickerStyle(.menu)
            }

            // District picker
            HStack {
                Text("District")
                    .foregroundColor(.secondary)
                Spacer()
                Picker("District", selection: $selectedDistrict) {
                    Text("Select District").tag("")
                    ForEach(IndianStates.districts(for: selectedState), id: \.self) { district in
                        Text(district).tag(district)
                    }
                }
                .pickerStyle(.menu)
                .disabled(selectedState.isEmpty)
            }

            Button(action: { locationManager.requestLocation() }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Use Current Location")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(10)
            }
        }
    }

    private var isFormValid: Bool {
        beforeImageData != nil &&
        afterImageData != nil &&
        !selectedState.isEmpty &&
        !selectedDistrict.isEmpty &&
        Double(wasteCollected) != nil &&
        (Double(wasteCollected) ?? 0) > 0
    }

    private func loadImage(from item: PhotosPickerItem?, completion: @escaping (Data?) -> Void) {
        guard let item = item else { return }
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    completion(data)
                case .failure:
                    completion(nil)
                }
            }
        }
    }

    private func submitPost() {
        guard isFormValid else { return }

        isSubmitting = true

        Task {
            do {
                try await PostService.shared.createPost(
                    description: description,
                    wasteCollectedKg: Double(wasteCollected) ?? 0,
                    durationMinutes: Int(duration),
                    state: selectedState,
                    district: selectedDistrict,
                    latitude: locationManager.location?.coordinate.latitude,
                    longitude: locationManager.location?.coordinate.longitude,
                    beforeImageData: beforeImageData!,
                    afterImageData: afterImageData!,
                    videoProofURL: videoProofURL.isEmpty ? nil : videoProofURL
                )
                await MainActor.run {
                    isSubmitting = false
                    onPostCreated()
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
    CreatePostView(onPostCreated: {})
}
