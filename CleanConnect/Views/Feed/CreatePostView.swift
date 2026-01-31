// CreatePostView.swift
// Minimal form for creating new cleanup posts - Video link is key!

import SwiftUI
import PhotosUI
import CoreLocation
import MapKit

// MARK: - Waste Categories
enum WasteCategory: String, CaseIterable, Identifiable {
    case plastic = "Plastic"
    case organic = "Organic"
    case mixed = "Mixed"
    case ewaste = "E-Waste"
    case hazardous = "Hazardous"
    case construction = "Construction"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .plastic: return "bottle.fill"
        case .organic: return "leaf.fill"
        case .mixed: return "trash.fill"
        case .ewaste: return "bolt.fill"
        case .hazardous: return "exclamationmark.triangle.fill"
        case .construction: return "hammer.fill"
        }
    }

    var color: Color {
        switch self {
        case .plastic: return .blue
        case .organic: return .green
        case .mixed: return .orange
        case .ewaste: return .purple
        case .hazardous: return .red
        case .construction: return .brown
        }
    }
}

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()

    // Required fields
    @State private var videoProofURL = ""
    @State private var selectedCategory: WasteCategory = .mixed
    @State private var selectedState = ""
    @State private var selectedDistrict = ""

    // Optional fields (expandable)
    @State private var showOptionalFields = false
    @State private var description = ""
    @State private var wasteCollected: Double = 0
    @State private var duration: Int = 0
    @State private var beforeImage: PhotosPickerItem?
    @State private var afterImage: PhotosPickerItem?
    @State private var beforeImageData: Data?
    @State private var afterImageData: Data?

    // State
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""

    var onPostCreated: () -> Void

    // Video URL, state, and district are required
    private var isFormValid: Bool {
        !videoProofURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedState.isEmpty &&
        !selectedDistrict.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero section - Video first!
                    videoHeroSection

                    // Quick category selector
                    categorySelector

                    // Required location section (always visible)
                    requiredLocationSection

                    // Optional fields toggle
                    optionalFieldsSection

                    // Points preview
                    pointsPreview
                }
                .padding()
            }
            .navigationTitle("Share Cleanup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { submitPost() }
                        .disabled(!isFormValid || isSubmitting)
                        .fontWeight(.bold)
                }
            }
            .overlay {
                if isSubmitting {
                    submittingOverlay
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Video Hero Section
    private var videoHeroSection: some View {
        VStack(spacing: 16) {
            // Big video icon
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)

                Image(systemName: "video.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }

            Text("Link Your Video Proof")
                .font(.title2.bold())

            Text("Paste a YouTube Shorts, Reel, or video link showing your cleanup")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Video URL input - prominent!
            HStack(spacing: 12) {
                Image(systemName: "link")
                    .foregroundColor(.secondary)

                TextField("youtube.com/shorts/... or instagram.com/reel/...", text: $videoProofURL)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .textContentType(.URL)

                if !videoProofURL.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Quick benefits
            if !videoProofURL.isEmpty {
                HStack(spacing: 16) {
                    benefitTag(icon: "checkmark.seal.fill", text: "Verified", color: .blue)
                    benefitTag(icon: "arrow.up.circle.fill", text: "Top Feed", color: .green)
                    benefitTag(icon: "indianrupeesign.circle.fill", text: "3x Tips", color: .orange)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
        .animation(.spring(), value: videoProofURL.isEmpty)
    }

    private func benefitTag(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption.bold())
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Category Selector
    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What did you clean?")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(WasteCategory.allCases) { category in
                    WasteCategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }

    // MARK: - Required Location Section (State & District)
    private var requiredLocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                Text("Location")
                    .font(.headline)
                Text("*")
                    .foregroundColor(.red)
            }

            // State picker
            VStack(alignment: .leading, spacing: 4) {
                Text("State")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("State", selection: $selectedState) {
                    Text("Select State").tag("")
                    ForEach(IndianStates.all, id: \.self) { state in
                        Text(state).tag(state)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(selectedState.isEmpty ? Color.red.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selectedState.isEmpty ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }

            // District picker
            VStack(alignment: .leading, spacing: 4) {
                Text("District")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("District", selection: $selectedDistrict) {
                    Text("Select District").tag("")
                    ForEach(IndianStates.districts(for: selectedState), id: \.self) { district in
                        Text(district).tag(district)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(selectedState.isEmpty)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(selectedDistrict.isEmpty ? Color.red.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selectedDistrict.isEmpty ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }

            if selectedState.isEmpty || selectedDistrict.isEmpty {
                Text("Please select your state and district")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    // MARK: - Optional Fields Section
    private var optionalFieldsSection: some View {
        VStack(spacing: 16) {
            // Toggle button
            Button(action: {
                withAnimation(.spring()) {
                    showOptionalFields.toggle()
                }
            }) {
                HStack {
                    Image(systemName: showOptionalFields ? "minus.circle.fill" : "plus.circle.fill")
                        .foregroundColor(.green)
                    Text(showOptionalFields ? "Hide Optional Details" : "Add More Details (Optional)")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(showOptionalFields ? 180 : 0))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            if showOptionalFields {
                VStack(spacing: 20) {
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        TextField("Tell us about your cleanup...", text: $description, axis: .vertical)
                            .lineLimit(2...4)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    // Weight & Duration with presets
                    weightAndDurationSection

                    // Photos (optional)
                    photosSection

                    // Location
                    locationSection
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Weight & Duration Presets
    private var weightAndDurationSection: some View {
        VStack(spacing: 16) {
            // Weight presets
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .foregroundColor(.orange)
                    Text("Waste Collected")
                        .font(.subheadline.weight(.medium))
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach([0.5, 1.0, 2.0, 5.0, 10.0, 20.0], id: \.self) { weight in
                            WeightPresetButton(
                                weight: weight,
                                isSelected: wasteCollected == weight
                            ) {
                                wasteCollected = weight
                            }
                        }

                        // Custom input
                        HStack {
                            TextField("Other", value: $wasteCollected, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                            Text("kg")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                    }
                }
            }

            // Duration presets
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Time Spent")
                        .font(.subheadline.weight(.medium))
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach([15, 30, 45, 60, 90, 120], id: \.self) { mins in
                            DurationPresetButton(
                                minutes: mins,
                                isSelected: duration == mins
                            ) {
                                duration = mins
                            }
                        }

                        // Custom input
                        HStack {
                            TextField("Other", value: $duration, format: .number)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                            Text("min")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Photos Section (Optional)
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(.purple)
                Text("Before & After Photos")
                    .font(.subheadline.weight(.medium))
                Text("(Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                // Before
                PhotosPicker(selection: $beforeImage, matching: .images) {
                    photoPickerContent(imageData: beforeImageData, label: "Before")
                }
                .onChange(of: beforeImage) { _, newValue in
                    loadImage(from: newValue) { data in
                        beforeImageData = data
                    }
                }

                // After
                PhotosPicker(selection: $afterImage, matching: .images) {
                    photoPickerContent(imageData: afterImageData, label: "After")
                }
                .onChange(of: afterImage) { _, newValue in
                    loadImage(from: newValue) { data in
                        afterImageData = data
                    }
                }
            }
        }
    }

    private func photoPickerContent(imageData: Data?, label: String) -> some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                ZStack(alignment: .topLeading) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()

                    Text(label)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .cornerRadius(4)
                        .padding(4)
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .clipped()
    }

    // MARK: - GPS Location Section (Optional - for precise coordinates)
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.blue)
                Text("GPS Coordinates")
                    .font(.subheadline.weight(.medium))
                Text("(Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if locationManager.location != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            // Current location button
            Button(action: { locationManager.requestLocation() }) {
                HStack {
                    if locationManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "location.fill")
                    }
                    Text(locationManager.location != nil ? "Location captured" : "Use Current Location")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(locationManager.location != nil ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                .foregroundColor(locationManager.location != nil ? .green : .blue)
                .cornerRadius(8)
            }

            Text("Adds your precise GPS coordinates for map display")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Points Preview
    private var pointsPreview: some View {
        HStack(spacing: 20) {
            VStack {
                Text("50")
                    .font(.title2.bold())
                    .foregroundColor(.green)
                Text("Base Points")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "plus")
                .foregroundColor(.secondary)

            VStack {
                Text("+25")
                    .font(.title2.bold())
                    .foregroundColor(.blue)
                Text("Video Bonus")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "equal")
                .foregroundColor(.secondary)

            VStack {
                Text("75")
                    .font(.title2.bold())
                    .foregroundColor(.orange)
                Text("Total Points")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Submitting Overlay
    private var submittingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Sharing your cleanup...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            )
    }

    // MARK: - Helper Methods
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
                    description: description.isEmpty ? "Cleanup completed! \(selectedCategory.rawValue) waste" : description,
                    wasteCollectedKg: wasteCollected > 0 ? wasteCollected : 1.0, // Default to 1kg if not specified
                    durationMinutes: duration > 0 ? duration : nil,
                    state: selectedState, // Required field
                    district: selectedDistrict, // Required field
                    latitude: locationManager.location?.coordinate.latitude,
                    longitude: locationManager.location?.coordinate.longitude,
                    beforeImageData: beforeImageData,
                    afterImageData: afterImageData,
                    videoProofURL: videoProofURL.trimmingCharacters(in: .whitespacesAndNewlines)
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

// MARK: - Waste Category Chip
struct WasteCategoryChip: View {
    let category: WasteCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title3)
                Text(category.rawValue)
                    .font(.caption2.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? category.color.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? category.color : .secondary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weight Preset Button
struct WeightPresetButton: View {
    let weight: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(weight < 1 ? "\(Int(weight * 10) * 100)g" : "\(Int(weight))kg")
                .font(.subheadline.weight(isSelected ? .bold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Duration Preset Button
struct DurationPresetButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    private var displayText: String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)hr"
        }
        return "\(minutes)m"
    }

    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(.subheadline.weight(isSelected ? .bold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreatePostView(onPostCreated: {})
}
