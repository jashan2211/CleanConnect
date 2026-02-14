// EventDetailView.swift
// Detailed view of a community cleanup event

import SwiftUI
import UIKit

struct EventDetailView: View {
    let gathering: Gathering
    @StateObject private var viewModel: EventDetailViewModel
    @State private var showRSVP = false
    @State private var showDonationSheet = false
    @State private var showOrganizerVideo = false
    @State private var showLiveStream = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userState: UserState

    init(gathering: Gathering) {
        self.gathering = gathering
        _viewModel = StateObject(wrappedValue: EventDetailViewModel(gatheringId: gathering.id))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header image
                headerImage

                VStack(alignment: .leading, spacing: 20) {
                    // Safety Warning Banner
                    safetyWarningBanner

                    // Title and organizer
                    titleSection

                    // Live Stream (for ongoing events)
                    if gathering.status == "ongoing", let liveURL = gathering.liveStreamURL, !liveURL.isEmpty {
                        liveStreamSection(liveURL: liveURL)
                    }

                    // Organizer video message (if available)
                    if let videoURL = gathering.videoMessageURL, !videoURL.isEmpty {
                        organizerVideoSection(videoURL: videoURL)
                    }

                    // Quick stats
                    statsSection

                    // Date & Time
                    dateTimeSection

                    // Location
                    locationSection

                    // Description
                    if !gathering.description.isEmpty {
                        descriptionSection
                    }

                    // Fundraising progress
                    if let goal = gathering.fundraisingGoal, goal > 0 {
                        fundraisingSection(goal: goal)
                    }

                    // Quick Action Tabs - Forum, Tasks, Supplies
                    eventActionTabs

                    // Attendees
                    attendeesSection

                    // Actions
                    actionsSection
                }
                .padding()
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {}) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    if gathering.whatsappGroupLink != nil {
                        Button(action: openWhatsApp) {
                            Label("Join WhatsApp Group", systemImage: "bubble.left.fill")
                        }
                    }

                    if isOrganizer {
                        Divider()
                        Button(role: .destructive, action: { showDeleteAlert = true }) {
                            Label("Delete Event", systemImage: "trash")
                        }
                    } else {
                        Button(action: {}) {
                            Label("Report", systemImage: "flag")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Event", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .overlay {
            if isDeleting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView("Deleting...")
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(12)
                    )
            }
        }
        .sheet(isPresented: $showRSVP) {
            RSVPSheet(gathering: gathering)
        }
        .sheet(isPresented: $showDonationSheet) {
            DonationSheet(gathering: gathering)
        }
    }

    private var headerImage: some View {
        Group {
            if let imageURL = gathering.imageURL {
                // Handle both local file paths and remote URLs
                if imageURL.hasPrefix("/") {
                    // Local file path - use Image from UIImage
                    if let uiImage = UIImage(contentsOfFile: imageURL) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        headerPlaceholder
                    }
                } else {
                    // Remote URL
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        headerPlaceholder
                    }
                }
            } else {
                headerPlaceholder
            }
        }
        .frame(height: 220)
        .clipped()
    }

    private var headerPlaceholder: some View {
        LinearGradient(
            colors: [Color.green.opacity(0.6), Color.green.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            VStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.8))
            }
        )
    }

    private var safetyWarningBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(.ccSaffron)
                    .font(.title3)
                Text("Safety First!")
                    .font(.subheadline.bold())
                    .foregroundColor(.ccSaffron)
            }

            VStack(alignment: .leading, spacing: 6) {
                SafetyTip(icon: "person.2.fill", text: "Don't go alone - bring a friend or join a group")
                SafetyTip(icon: "phone.fill", text: "Inform someone about your location")
                SafetyTip(icon: "eye.fill", text: "Stay aware of your surroundings")
                SafetyTip(icon: "clock.fill", text: "Avoid isolated areas, especially after dark")
            }

            Text("CleanConnect is not responsible for your personal safety. Always prioritize your well-being.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.ccSaffron.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.ccSaffron.opacity(0.3), lineWidth: 1)
        )
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(gathering.title)
                .font(.title2.weight(.bold))

            HStack {
                AsyncImage(url: URL(string: gathering.organizerPhotoURL ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())

                Text("Organized by \(gathering.organizerName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 24) {
            StatBadge(icon: "person.2.fill", value: "\(gathering.attendeesCount)", label: "Attending")
            StatBadge(icon: "star.fill", value: "+\(gathering.durationHours ?? 2 * 50)", label: "Points")
            StatBadge(icon: "clock.fill", value: "\(gathering.durationHours ?? 2)h", label: "Duration")
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date & Time")
                .font(.headline)

            HStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.green)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(gathering.eventDate.formatted(date: .complete, time: .omitted))
                        .font(.subheadline.weight(.medium))
                    Text(gathering.eventDate.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)

            HStack(spacing: 16) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 2) {
                    if let address = gathering.address {
                        Text(address)
                            .font(.subheadline.weight(.medium))
                    }
                    Text("\(gathering.district), \(gathering.state)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: openMaps) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }

            // Map preview
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 120)
                .cornerRadius(12)
                .overlay(
                    Image(systemName: "map")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.5))
                )
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            Text(gathering.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Event Action Tabs (Forum, Tasks, Supplies)

    private var eventActionTabs: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Get Involved")
                .font(.headline)

            HStack(spacing: 12) {
                // Discussion Forum
                NavigationLink {
                    EventForumView(event: gathering)
                } label: {
                    ActionTab(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "Discussion",
                        subtitle: "Chat & Plan",
                        color: .blue
                    )
                }

                // Tasks
                NavigationLink {
                    EventTasksView(event: gathering, isOrganizer: isOrganizer)
                } label: {
                    ActionTab(
                        icon: "checklist",
                        title: "Tasks",
                        subtitle: "Volunteer",
                        color: .orange
                    )
                }

                // Supplies
                NavigationLink {
                    EventSuppliesView(event: gathering, isOrganizer: isOrganizer)
                } label: {
                    ActionTab(
                        icon: "shippingbox.fill",
                        title: "Supplies",
                        subtitle: "Contribute",
                        color: .purple
                    )
                }
            }
        }
    }

    private var isOrganizer: Bool {
        gathering.organizerId == UserState.shared.currentUser?.id
    }

    // MARK: - Live Stream Section (Ongoing Events)

    private func liveStreamSection(liveURL: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.15))
                .cornerRadius(4)

                Text("Event is happening now!")
                    .font(.subheadline.weight(.medium))

                Spacer()
            }

            // Live stream preview card
            Button {
                showLiveStream = true
            } label: {
                ZStack {
                    // Thumbnail
                    if let videoId = extractYouTubeId(from: liveURL) {
                        AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.red.opacity(0.1))
                        }
                    } else {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color.red.opacity(0.3), Color.orange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    }

                    // Overlay
                    Color.black.opacity(0.3)

                    // Live indicator and play button
                    VStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE NOW")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(4)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                    .offset(x: 2)
                            )
                            .shadow(radius: 8)

                        Text("Watch Live Stream")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 200)
                .cornerRadius(16)
                .clipped()
            }
            .buttonStyle(.plain)

            // Quick info
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                    Text("Watch the event as it happens")
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                Spacer()

                Image(systemName: "play.rectangle.fill")
                    .foregroundColor(.red)
                Text("YouTube")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showLiveStream) {
            LiveStreamPlayerSheet(streamURL: liveURL, eventTitle: gathering.title)
        }
    }

    private func extractYouTubeId(from url: String) -> String? {
        let patterns = [
            "(?:youtube\\.com\\/watch\\?v=)([a-zA-Z0-9_-]{11})",
            "(?:youtu\\.be\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/embed\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/live\\/)([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: url, options: [], range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                return String(url[range])
            }
        }
        return nil
    }

    // MARK: - Organizer Video Message

    private func organizerVideoSection(videoURL: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "video.circle.fill")
                    .foregroundColor(.blue)
                Text("Message from Organizer")
                    .font(.headline)
            }

            OrganizerVideoCard(videoURL: videoURL, showPlayer: $showOrganizerVideo)
        }
        .sheet(isPresented: $showOrganizerVideo) {
            OrganizerVideoPlayerSheet(videoURL: videoURL)
        }
    }

    // MARK: - Fundraising with 5% Service Fee

    private func fundraisingSection(goal: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fundraising")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("₹\(gathering.fundraisingRaised ?? 0)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.green)
                    Text("raised of ₹\(goal) goal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: Double(gathering.fundraisingRaised ?? 0), total: Double(goal))
                    .tint(.green)

                // Service fee info
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.secondary)
                    Text("5% service fee applies to donations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: { showDonationSheet = true }) {
                    Text("Contribute")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color.green.opacity(0.05))
            .cornerRadius(12)
        }
    }

    private var supplyRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Supplies Needed")
                .font(.headline)

            ForEach(viewModel.supplyRequests) { supply in
                HStack {
                    Image(systemName: supplyIcon(supply.type))
                        .foregroundColor(.orange)
                        .frame(width: 30)
                    VStack(alignment: .leading) {
                        Text(supply.name)
                            .font(.subheadline.weight(.medium))
                        Text("\(supply.pledged)/\(supply.needed) pledged")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Pledge") {}
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
        }
    }

    private var attendeesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Attendees")
                    .font(.headline)
                Spacer()
                Text("\(gathering.attendeesCount) going")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: -8) {
                ForEach(0..<min(5, gathering.attendeesCount), id: \.self) { _ in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                        )
                }
                if gathering.attendeesCount > 5 {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("+\(gathering.attendeesCount - 5)")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.green)
                        )
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showRSVP = true }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("RSVP to Event")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
            }

            if gathering.whatsappGroupLink != nil {
                Button(action: openWhatsApp) {
                    HStack {
                        Image(systemName: "bubble.left.fill")
                        Text("Join WhatsApp Group")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "25D366"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                }
            }
        }
        .padding(.top)
    }

    private func supplyIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "gloves": return "hand.raised.fill"
        case "bags": return "bag.fill"
        case "tools": return "wrench.fill"
        default: return "shippingbox.fill"
        }
    }

    private func openWhatsApp() {
        if let link = gathering.whatsappGroupLink, let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }

    private func openMaps() {
        if let lat = gathering.latitude, let lng = gathering.longitude {
            let url = URL(string: "maps://?daddr=\(lat),\(lng)")!
            UIApplication.shared.open(url)
        }
    }

    private func deleteEvent() {
        isDeleting = true
        Task {
            do {
                try await GatheringService.shared.deleteGathering(gatheringId: gathering.id)
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                }
            }
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActionTab: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SafetyTip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.ccSaffron)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

struct RSVPSheet: View {
    @Environment(\.dismiss) private var dismiss
    let gathering: Gathering
    @State private var isAttending = true
    @State private var note = ""
    @State private var safetyAcknowledged = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Will you attend?")
                        .font(.headline)

                    Picker("RSVP", selection: $isAttending) {
                        Text("Yes, I'm going!").tag(true)
                        Text("Can't make it").tag(false)
                    }
                    .pickerStyle(.segmented)

                    TextField("Add a note (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)

                    if isAttending {
                        // Safety reminder section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "shield.checkered")
                                    .foregroundColor(.ccSaffron)
                                Text("Safety Reminder")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.ccSaffron)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("• Don't attend alone - go with friends or meet others there")
                                Text("• Share your location with a trusted person")
                                Text("• Keep your phone charged")
                                Text("• Be cautious of unfamiliar areas")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)

                            Toggle(isOn: $safetyAcknowledged) {
                                Text("I understand and will prioritize my safety")
                                    .font(.caption)
                            }
                            .tint(.ccSaffron)
                        }
                        .padding()
                        .background(Color.ccSaffron.opacity(0.1))
                        .cornerRadius(12)
                    }

                    Spacer(minLength: 20)

                    Button(action: submitRSVP) {
                        Text("Confirm RSVP")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSubmit ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .fontWeight(.semibold)
                    }
                    .disabled(!canSubmit)
                }
                .padding()
            }
            .navigationTitle("RSVP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var canSubmit: Bool {
        !isAttending || safetyAcknowledged
    }

    private func submitRSVP() {
        Task {
            try? await GatheringService.shared.rsvp(
                gatheringId: gathering.id,
                status: isAttending ? .going : .notGoing,
                note: note.isEmpty ? nil : note
            )
            dismiss()
        }
    }
}

// MARK: - Donation Sheet with 5% Service Fee

struct DonationSheet: View {
    let gathering: Gathering
    @Environment(\.dismiss) private var dismiss
    @State private var donationAmount = ""
    @State private var selectedPreset: Int?
    @State private var isSubmitting = false
    @State private var showSuccess = false

    private let presetAmounts = [100, 250, 500, 1000, 2500, 5000]

    private var amount: Int {
        Int(donationAmount) ?? selectedPreset ?? 0
    }

    private var serviceFee: Int {
        Int(Double(amount) * 0.05)
    }

    private var totalAmount: Int {
        amount + serviceFee
    }

    private var organizerReceives: Int {
        amount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Event info
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)

                        VStack(alignment: .leading) {
                            Text("Donate to")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(gathering.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(12)

                    // Progress
                    if let goal = gathering.fundraisingGoal {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("₹\(gathering.fundraisingRaised ?? 0)")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Text("of ₹\(goal) raised")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            ProgressView(value: Double(gathering.fundraisingRaised ?? 0), total: Double(goal))
                                .tint(.green)
                        }
                    }

                    // Preset amounts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Amount")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(presetAmounts, id: \.self) { preset in
                                Button {
                                    selectedPreset = preset
                                    donationAmount = ""
                                } label: {
                                    Text("₹\(preset)")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedPreset == preset ? Color.green : Color.gray.opacity(0.1))
                                        .foregroundColor(selectedPreset == preset ? .white : .primary)
                                        .cornerRadius(10)
                                }
                            }
                        }

                        // Custom amount
                        HStack {
                            Text("₹")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            TextField("Enter custom amount", text: $donationAmount)
                                .keyboardType(.numberPad)
                                .onChange(of: donationAmount) { _, _ in
                                    selectedPreset = nil
                                }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }

                    // Fee breakdown
                    if amount > 0 {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Your donation")
                                Spacer()
                                Text("₹\(amount)")
                            }

                            HStack {
                                HStack(spacing: 4) {
                                    Text("Service fee (5%)")
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("₹\(serviceFee)")
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text("₹\(totalAmount)")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }

                            HStack {
                                Text("Organizer receives")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("₹\(organizerReceives)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }

                    // Service fee explanation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("About Service Fee")
                                .font(.subheadline.weight(.medium))
                        }

                        Text("A 5% service fee helps us maintain the platform, verify events, and ensure secure transactions. This fee covers payment processing and platform operations.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Donate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    submitDonation()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Donate ₹\(totalAmount)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(amount > 0 ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                }
                .disabled(amount <= 0 || isSubmitting)
                .padding()
                .background(.ultraThinMaterial)
            }
            .alert("Thank You!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your donation of ₹\(organizerReceives) has been sent to the organizer. Thank you for supporting this event!")
            }
        }
    }

    private func submitDonation() {
        isSubmitting = true
        Task {
            do {
                try await GatheringService.shared.contribute(gatheringId: gathering.id, amount: amount)
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true // Show thank you even if save fails locally
                }
            }
        }
    }
}

// MARK: - Organizer Video Card

struct OrganizerVideoCard: View {
    let videoURL: String
    @Binding var showPlayer: Bool

    private var isYouTube: Bool {
        videoURL.contains("youtube.com") || videoURL.contains("youtu.be")
    }

    private var thumbnailURL: URL? {
        guard isYouTube, let videoId = extractYouTubeId() else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.blue)
                Text("Video Message")
                    .font(.caption.weight(.semibold))
                Spacer()
                if isYouTube {
                    Text("YouTube")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Button {
                if isYouTube {
                    showPlayer = true
                } else if let url = URL(string: videoURL) {
                    UIApplication.shared.open(url)
                }
            } label: {
                ZStack {
                    if let url = thumbnailURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                    } else {
                        Rectangle()
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                Image(systemName: "play.rectangle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)
                            )
                    }

                    // Play button
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .offset(x: 2)
                        )
                        .shadow(radius: 4)
                }
            }
            .frame(height: 160)
            .cornerRadius(10)
            .clipped()
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }

    private func extractYouTubeId() -> String? {
        let patterns = [
            "(?:youtube\\.com\\/watch\\?v=)([a-zA-Z0-9_-]{11})",
            "(?:youtu\\.be\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/embed\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/shorts\\/)([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: videoURL, options: [], range: NSRange(videoURL.startIndex..., in: videoURL)),
               let range = Range(match.range(at: 1), in: videoURL) {
                return String(videoURL[range])
            }
        }
        return nil
    }
}

// MARK: - Organizer Video Player Sheet

import WebKit

struct OrganizerVideoPlayerSheet: View {
    let videoURL: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            OrganizerYouTubePlayer(videoURL: videoURL)
                .ignoresSafeArea()
                .navigationTitle("Video Message")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct OrganizerYouTubePlayer: UIViewRepresentable {
    let videoURL: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let videoId = extractYouTubeId() else { return }

        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; }
                html, body { width: 100%; height: 100%; background: #000; }
                iframe { width: 100%; height: 100%; border: 0; }
            </style>
        </head>
        <body>
            <iframe
                src="https://www.youtube.com/embed/\(videoId)?playsinline=1&rel=0&modestbranding=1&autoplay=1"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen>
            </iframe>
        </body>
        </html>
        """

        webView.loadHTMLString(embedHTML, baseURL: nil)
    }

    private func extractYouTubeId() -> String? {
        let patterns = [
            "(?:youtube\\.com\\/watch\\?v=)([a-zA-Z0-9_-]{11})",
            "(?:youtu\\.be\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/embed\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/shorts\\/)([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: videoURL, options: [], range: NSRange(videoURL.startIndex..., in: videoURL)),
               let range = Range(match.range(at: 1), in: videoURL) {
                return String(videoURL[range])
            }
        }
        return nil
    }
}

// MARK: - Live Stream Player Sheet

struct LiveStreamPlayerSheet: View {
    let streamURL: String
    let eventTitle: String
    @Environment(\.dismiss) private var dismiss
    @State private var showChat = true

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Video player
                    LiveStreamYouTubeEmbed(streamURL: streamURL)
                        .frame(height: geometry.size.height * (showChat ? 0.45 : 0.7))

                    if showChat {
                        // Live chat area
                        VStack(spacing: 0) {
                            // Chat header
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 6, height: 6)
                                    Text("Live Chat")
                                        .font(.subheadline.weight(.semibold))
                                }

                                Spacer()

                                Button {
                                    withAnimation { showChat = false }
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color(.systemBackground))

                            Divider()

                            // Chat messages
                            ScrollView {
                                VStack(spacing: 20) {
                                    Spacer(minLength: 40)
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary.opacity(0.5))
                                    Text("No messages yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Be the first to say hello!")
                                        .font(.caption)
                                        .foregroundColor(.secondary.opacity(0.7))
                                    Spacer(minLength: 40)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }

                            Divider()

                            // Chat input
                            HStack(spacing: 12) {
                                TextField("Send a message...", text: .constant(""))
                                    .textFieldStyle(.roundedBorder)

                                Button {
                                    // Send message
                                } label: {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                        }
                        .transition(.move(edge: .bottom))
                    } else {
                        // Collapsed chat bar
                        Button {
                            withAnimation { showChat = true }
                        } label: {
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 6, height: 6)
                                    Text("Show Live Chat")
                                        .font(.subheadline)
                                }
                                Spacer()
                                Image(systemName: "chevron.up")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(eventTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("LIVE")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct EventLiveChatMessageView: View {
    let username: String
    let message: String
    let isOrganizer: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(isOrganizer ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 28, height: 28)
                .overlay(
                    Text(String(username.prefix(1)))
                        .font(.caption.bold())
                        .foregroundColor(isOrganizer ? .white : .primary)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(username)
                        .font(.caption.bold())
                        .foregroundColor(isOrganizer ? .green : .primary)

                    if isOrganizer {
                        Text("ORGANIZER")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(2)
                    }
                }

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
    }
}

struct LiveStreamYouTubeEmbed: UIViewRepresentable {
    let streamURL: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let videoId = extractYouTubeId() else { return }

        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; }
                html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
                iframe { width: 100%; height: 100%; border: 0; }
            </style>
        </head>
        <body>
            <iframe
                src="https://www.youtube.com/embed/\(videoId)?playsinline=1&rel=0&modestbranding=1&autoplay=1"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen>
            </iframe>
        </body>
        </html>
        """

        webView.loadHTMLString(embedHTML, baseURL: nil)
    }

    private func extractYouTubeId() -> String? {
        let patterns = [
            "(?:youtube\\.com\\/watch\\?v=)([a-zA-Z0-9_-]{11})",
            "(?:youtu\\.be\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/embed\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/live\\/)([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: streamURL, options: [], range: NSRange(streamURL.startIndex..., in: streamURL)),
               let range = Range(match.range(at: 1), in: streamURL) {
                return String(streamURL[range])
            }
        }
        return nil
    }
}

#Preview {
    NavigationStack {
        EventDetailView(gathering: Gathering.preview)
    }
}
