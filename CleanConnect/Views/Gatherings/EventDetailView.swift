// EventDetailView.swift
// Detailed view of a community cleanup event

import SwiftUI

struct EventDetailView: View {
    let gathering: Gathering
    @StateObject private var viewModel: EventDetailViewModel
    @State private var showRSVP = false

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

                    // Supply requests
                    if !viewModel.supplyRequests.isEmpty {
                        supplyRequestsSection
                    }

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
                    Button(action: {}) {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showRSVP) {
            RSVPSheet(gathering: gathering)
        }
    }

    private var headerImage: some View {
        Group {
            if let imageURL = gathering.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    headerPlaceholder
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
            StatBadge(icon: "star.fill", value: "+100", label: "Points")
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

                Button(action: {}) {
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
        // Submit RSVP logic
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EventDetailView(gathering: Gathering.preview)
    }
}
