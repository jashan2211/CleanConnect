import SwiftUI
import EventKit
import EventKitUI

struct DriveDetailView: View {
    let driveId: String
    @Environment(Session.self) private var session
    @Environment(LocationService.self) private var location
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var drive: Drive?
    @State private var loaded = false
    @State private var attendees: [Attendee] = []
    @State private var attending = false
    @State private var working = false
    @State private var showCalendar = false
    @State private var showSupport = false
    @State private var showComplete = false
    @State private var flagTarget: FlagTarget?
    @State private var confirmCancel = false
    @State private var linkedSpot: Spot?

    var body: some View {
        Group {
            if let drive {
                content(drive)
            } else if loaded {
                EmptyStateView(icon: "questionmark.circle", title: "Drive not found", message: "It may have been cancelled.")
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.ccBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            for await value in DriveAPI.drive(driveId) {
                drive = value
                loaded = true
            }
        }
        .task {
            for await list in DriveAPI.attendees(driveId) {
                attendees = list
                if let uid = session.uid { attending = list.contains { $0.uid == uid } }
            }
        }
        .task(id: drive?.spotId) {
            guard let spotId = drive?.spotId else { return }
            for await spot in SpotAPI.spot(spotId) { linkedSpot = spot }
        }
        .sheet(isPresented: $showCalendar) {
            if let drive { CalendarSheet(drive: drive).ignoresSafeArea() }
        }
        .sheet(isPresented: $showSupport) {
            if let drive {
                SupportSheet(name: drive.organizerName, photoURL: drive.organizerPhoto, upiId: drive.upiId, context: .drive(drive.title))
            }
        }
        .sheet(isPresented: $showComplete) {
            if let drive { CompleteDriveView(drive: drive, linkedSpot: linkedSpot) }
        }
        .sheet(item: $flagTarget) { FlagSheet(target: $0) }
        .confirmationDialog("Cancel this drive?", isPresented: $confirmCancel, titleVisibility: .visible) {
            Button("Cancel drive", role: .destructive) {
                guard let drive else { return }
                run {
                    try await DriveAPI.cancel(drive)
                    dismiss()
                }
            }
        } message: {
            Text("Volunteers who joined will see it as cancelled.")
        }
    }

    private func content(_ drive: Drive) -> some View {
        let isOrganizer = drive.organizerId == session.uid
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cover(drive)
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        if drive.status == .done {
                            Label("Completed", systemImage: "checkmark.seal.fill")
                                .font(.cc(.caption, weight: .bold)).foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 5).background(Color.ccCleaned, in: Capsule())
                        }
                        Text(drive.title).font(.ccLargeTitle).foregroundStyle(Color.ccInk)
                        NavigationLink(value: Route.profile(drive.organizerId)) {
                            HStack(spacing: 8) {
                                Avatar(url: drive.organizerPhoto, name: drive.organizerName, size: 30)
                                Text("Organised by \(Text(drive.organizerName).bold())").font(.cc(.subheadline)).foregroundStyle(Color.ccInk2)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    infoCard(drive)
                    joinPanel(drive, isOrganizer: isOrganizer)
                    attendeesBlock(drive)

                    if !drive.about.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About").font(.ccTitle3).foregroundStyle(Color.ccInk)
                            Text(drive.about).font(.cc(.body)).foregroundStyle(Color.ccInk)
                        }
                    }

                    if !drive.bring.isEmpty { itemsBlock("Bring along", items: drive.bring, tint: .ccBlue) }
                    if !drive.providing.isEmpty { itemsBlock("Provided by organiser", items: drive.providing, tint: .ccGreen) }

                    if let spot = linkedSpot {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("The spot we're cleaning").font(.ccTitle3).foregroundStyle(Color.ccInk)
                            NavigationLink(value: Route.spot(spot.id)) { SpotRow(spot: spot, origin: location.location) }
                                .buttonStyle(.pressable)
                        }
                    }

                    if drive.status == .done && !drive.resultPhotos.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Results: \(drive.resultBags) bags collected").font(.ccTitle3).foregroundStyle(Color.ccInk)
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(drive.resultPhotos, id: \.self) { url in
                                        RemoteImage(url).frame(width: 220, height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
                        }
                    }

                    safetyNote

                    CommentsSection(parent: DB.drives.document(drive.id), count: drive.commentCount, title: "Questions & updates") { comment in
                        flagTarget = .driveComment(driveId: drive.id, commentId: comment.id)
                    }
                }
                .padding(.horizontal, Metrics.gutter)
            }
            .padding(.bottom, 40)
            .readableWidth(760)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: inviteText(drive)) { Image(systemName: "square.and.arrow.up") }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if isOrganizer && drive.status == .upcoming {
                        Button { showComplete = true } label: { Label("Mark as completed", systemImage: "checkmark.seal") }
                        Button(role: .destructive) { confirmCancel = true } label: { Label("Cancel drive", systemImage: "xmark.circle") }
                    }
                    if session.isSignedIn && !isOrganizer {
                        Button { flagTarget = .drive(drive.id) } label: { Label("Report drive", systemImage: "flag") }
                        Button(role: .destructive) {
                            Task { await session.block(drive.organizerId); dismiss() }
                        } label: { Label("Block organiser", systemImage: "hand.raised") }
                    }
                    Button { Directions.open(drive.coordinate, name: drive.title) } label: {
                        Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
    }

    private func cover(_ drive: Drive) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let url = drive.coverURL {
                RemoteImage(url)
            } else {
                ZStack {
                    LinearGradient.ccSaffron
                    Image(systemName: "person.3.fill").font(.system(size: 80, weight: .bold)).foregroundStyle(.white.opacity(0.3))
                }
            }
            DateBlock(date: drive.startsAt).padding(16)
        }
        .frame(height: 240)
        .clipped()
    }

    private func infoCard(_ drive: Drive) -> some View {
        VStack(spacing: 0) {
            infoRow(icon: "calendar", tint: .ccSaffron,
                    title: drive.startsAt.formatted(.dateTime.weekday(.wide).day().month(.wide)),
                    subtitle: "\(Fmt.time(drive.startsAt)) – \(Fmt.time(drive.endsAt))") {
                Button("Add") { showCalendar = true }.font(.cc(.subheadline, weight: .bold))
            }
            Divider().padding(.leading, 52)
            infoRow(icon: "mappin.and.ellipse", tint: .ccDirty, title: drive.address.nilIfEmpty ?? drive.city,
                    subtitle: [drive.city, Fmt.distance(from: location.location, to: drive.location).map { String(localized: "\($0) away") }]
                        .compactMap { $0?.nilIfEmpty }.joined(separator: " · ")) {
                Button("Go") { Directions.open(drive.coordinate, name: drive.title) }.font(.cc(.subheadline, weight: .bold))
            }
            MiniMap(coordinate: drive.coordinate, tint: .ccSaffron, height: 120).padding(.top, 8)
        }
        .ccCard(padding: 14)
    }

    private func infoRow<Trailing: View>(icon: String, tint: Color, title: String, subtitle: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundStyle(tint)
                .frame(width: 40, height: 40).background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk)
                if !subtitle.isEmpty { Text(subtitle).font(.cc(.caption)).foregroundStyle(Color.ccInk2) }
            }
            Spacer()
            trailing()
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func joinPanel(_ drive: Drive, isOrganizer: Bool) -> some View {
        VStack(spacing: 10) {
            if drive.status == .upcoming && !drive.isPast {
                if isOrganizer {
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill").foregroundStyle(Color.ccSaffron)
                        Text("You're organising this drive. Share the invite to get more people.")
                            .font(.cc(.subheadline)).foregroundStyle(Color.ccInk)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    ShareLink(item: inviteText(drive)) { Label("Invite on WhatsApp & more", systemImage: "paperplane.fill") }
                        .buttonStyle(.primary(.ccSaffron))
                } else if attending {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.ccGreen).font(.title2)
                        VStack(alignment: .leading) {
                            Text("You're going!").font(.cc(.headline, weight: .bold)).foregroundStyle(Color.ccInk)
                            Text("We'll remind you the day before.").font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                        }
                        Spacer()
                        Button("Leave") {
                            guard let uid = session.uid else { return }
                            run {
                                try await DriveAPI.leave(drive.id, uid: uid)
                                Reminders.cancel(for: drive.id)
                                attending = false
                            }
                        }
                        .buttonStyle(.secondary(.ccInk2, fullWidth: false))
                    }
                    ShareLink(item: inviteText(drive)) { Label("Bring a friend", systemImage: "person.badge.plus") }
                        .buttonStyle(.secondary(.ccSaffron))
                } else {
                    Button {
                        guard session.gate("Sign in to join this cleanup drive."), let profile = session.profile else { return }
                        run {
                            try await DriveAPI.join(drive.id, profile: profile)
                            attending = true
                            await Reminders.schedule(for: drive)
                            session.celebrate("You're in! See you there.", points: Points.joinDrive, icon: "person.3.fill")
                        }
                    } label: {
                        Label(drive.isFull ? "Drive is full" : "Join this drive", systemImage: "hand.wave.fill")
                    }
                    .buttonStyle(.primary(.ccSaffron))
                    .disabled(drive.isFull)
                }
                if let link = drive.whatsappLink, let url = URL(string: link), attending || isOrganizer {
                    Button { openURL(url) } label: { Label("Open WhatsApp group", systemImage: "bubble.left.and.bubble.right.fill") }
                        .buttonStyle(.secondary(Color(hex: 0x25D366)))
                }
            }
            if drive.upiId != nil && !isOrganizer {
                Button { showSupport = true } label: {
                    Label("Chip in for supplies via UPI", systemImage: "indianrupeesign.circle.fill")
                }
                .buttonStyle(.secondary(.ccSaffron))
            }
        }
        .disabled(working)
    }

    private func attendeesBlock(_ drive: Drive) -> some View {
        let visible = attendees.filter { !session.isBlocked($0.uid) }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Who's going").font(.ccTitle3).foregroundStyle(Color.ccInk)
                Spacer()
                Text(drive.capacity.map { "\(drive.attendeeCount)/\($0)" } ?? "\(drive.attendeeCount)")
                    .font(.ccNumber(17)).foregroundStyle(Color.ccSaffron)
            }
            if let cap = drive.capacity {
                ProgressView(value: Double(min(drive.attendeeCount, cap)), total: Double(cap)).tint(.ccSaffron)
            }
            if visible.isEmpty {
                Text("Be the first to join!").font(.cc(.subheadline)).foregroundStyle(Color.ccInk2)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 14) {
                        ForEach(visible.prefix(30)) { person in
                            NavigationLink(value: Route.profile(person.uid)) {
                                VStack(spacing: 4) {
                                    Avatar(url: person.photoURL, name: person.name, size: 48)
                                    Text(person.name.split(separator: " ").first.map(String.init) ?? person.name)
                                        .font(.cc(.caption2, weight: .semibold)).foregroundStyle(Color.ccInk2).lineLimit(1)
                                }
                                .frame(width: 58)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .ccCard()
    }

    private func itemsBlock(_ title: LocalizedStringKey, items: [DriveItem], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.ccTitle3).foregroundStyle(Color.ccInk)
            FlowLayout(spacing: 8) {
                ForEach(items) { item in
                    Label(item.title, systemImage: item.icon)
                        .font(.cc(.subheadline, weight: .semibold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(tint.opacity(0.1), in: Capsule())
                }
            }
        }
    }

    private var safetyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.shield.fill").foregroundStyle(Color.ccSaffron)
            Text("Safety first: go with others, wear gloves and closed shoes, keep kids supervised, stay away from traffic, and never handle needles or medical waste.")
                .font(.cc(.caption)).foregroundStyle(Color.ccInk2)
        }
        .padding(12)
        .background(Color.ccSaffronSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func inviteText(_ drive: Drive) -> String {
        let when = drive.startsAt.formatted(.dateTime.weekday(.wide).day().month(.wide).hour().minute())
        let place = drive.placeLabel
        return String(localized: "🧹 Join our cleanup drive: \(drive.title)\n📅 \(when)\n📍 \(place)\n🗺️ \(Directions.mapsLink(drive.coordinate))\n\nRSVP on CleanConnect: \(AppConfig.appStoreURL.absoluteString)")
    }

    private func run(_ work: @escaping () async throws -> Void) {
        working = true
        Task {
            do { try await work() } catch { session.show(error: error) }
            working = false
        }
    }
}

/// System "add event" sheet. Works without calendar permission on iOS 17+.
struct CalendarSheet: UIViewControllerRepresentable {
    let drive: Drive
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = drive.title
        event.startDate = drive.startsAt
        event.endDate = drive.endsAt
        event.location = drive.placeLabel
        event.notes = String(localized: "Cleanup drive on CleanConnect. Bring water, a cap and closed shoes.")
        event.addAlarm(EKAlarm(relativeOffset: -3600))
        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            dismiss()
        }
    }
}

/// Organiser posts results after the drive.
struct CompleteDriveView: View {
    let drive: Drive
    var linkedSpot: Spot?
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var result = DriveResult()
    @State private var submitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Photos from the drive") {
                    PhotoStrip(photos: $result.photos, limit: 4, tint: .ccGreen)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }
                Section("Impact") {
                    Stepper(value: $result.bags, in: 0...1000) {
                        Label("\(result.bags) bags collected", systemImage: "bag.fill")
                    }
                    TextField("How did it go? (optional)", text: $result.note, axis: .vertical).lineLimit(2...4)
                }
                if linkedSpot?.status != .cleaned, linkedSpot != nil {
                    Section {
                        Text("The linked spot will also be marked as cleaned with these photos.")
                            .font(.cc(.footnote)).foregroundStyle(Color.ccInk2)
                    }
                }
            }
            .navigationTitle("Complete drive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { submit() }.disabled(result.photos.isEmpty || submitting)
                }
            }
            .overlay { if submitting { ProgressView().controlSize(.large) } }
        }
    }

    private func submit() {
        guard let profile = session.profile else { return }
        submitting = true
        Task {
            do {
                try await DriveAPI.complete(drive, result: result)
                if let spot = linkedSpot, spot.status != .cleaned {
                    let report = CleanupReport(photos: Array(result.photos.prefix(3)), bags: result.bags,
                                               crew: max(drive.attendeeCount, 1), note: result.note)
                    try? await SpotAPI.markCleaned(spot, report: report, by: profile, driveId: drive.id)
                }
                dismiss()
                session.celebrate("Drive complete! What a team.", points: Points.completeDrive + Points.perBag * min(result.bags, Points.maxBagsCounted), icon: "flag.checkered")
            } catch {
                session.show(error: error)
            }
            submitting = false
        }
    }
}
