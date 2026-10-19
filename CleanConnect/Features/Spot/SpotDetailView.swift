import SwiftUI
import MapKit

struct SpotDetailView: View {
    let spotId: String
    @Environment(Session.self) private var session
    @Environment(LocationService.self) private var location
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss

    @State private var spot: Spot?
    @State private var loaded = false
    @State private var reactions: Set<ReactionKind> = []
    @State private var countDelta: [ReactionKind: Int] = [:]
    @State private var showCleanup = false
    @State private var flagTarget: FlagTarget?
    @State private var confirmDelete = false
    @State private var supportProfile: Profile?
    @State private var shareImage: Image?
    @State private var working = false

    var body: some View {
        Group {
            if let spot {
                content(spot)
            } else if loaded {
                EmptyStateView(icon: "questionmark.circle", title: "Spot not found", message: "It may have been removed.")
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.ccBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            for await value in SpotAPI.spot(spotId) {
                withAnimation(.snappy) { spot = value }
                countDelta = [:]
                loaded = true
            }
        }
        .task(id: session.uid) {
            guard let uid = session.uid else { reactions = []; return }
            reactions = await SpotAPI.myReactions(on: spotId, uid: uid)
        }
        .task(id: spot?.status) {
            guard let spot else { return }
            shareImage = spot.status == .cleaned ? await ShareCards.cleanupCard(for: spot) : await ShareCards.reportCard(for: spot)
        }
        .sheet(isPresented: $showCleanup) {
            if let spot { CleanupView(spot: spot) }
        }
        .sheet(item: $flagTarget) { target in FlagSheet(target: target) }
        .sheet(item: $supportProfile) { profile in SupportSheet(recipient: profile, context: .cleanup) }
        .confirmationDialog("Delete this report?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                guard let spot else { return }
                Task {
                    do { try await SpotAPI.delete(spot); dismiss() } catch { session.show(error: error) }
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ spot: Spot) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero(spot)
                VStack(alignment: .leading, spacing: 20) {
                    titleBlock(spot)
                    actionPanel(spot)
                    reactionsRow(spot)
                    if spot.status == .cleaned { cleanupInfo(spot) }
                    if !spot.note.isEmpty { noteBlock(spot) }
                    locationBlock(spot)
                    CommentsSection(parent: DB.spots.document(spot.id), count: spot.commentCount) { comment in
                        flagTarget = .spotComment(spotId: spot.id, commentId: comment.id)
                    }
                }
                .padding(.horizontal, Metrics.gutter)
            }
            .padding(.bottom, 40)
            .readableWidth(760)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let shareImage {
                    ShareLink(item: shareImage, message: Text(shareMessage(spot)), preview: SharePreview("CleanConnect", image: shareImage)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { router.showOnMap(spot) } label: { Label("Show on map", systemImage: "map") }
                    if spot.reporterId == session.uid && spot.status == .open {
                        Button(role: .destructive) { confirmDelete = true } label: { Label("Delete report", systemImage: "trash") }
                    }
                    if session.isSignedIn && spot.reporterId != session.uid {
                        Button { flagTarget = .spot(spot.id) } label: { Label("Report content", systemImage: "flag") }
                        Button(role: .destructive) {
                            Task { await session.block(spot.reporterId); dismiss() }
                        } label: { Label("Block \(spot.reporterName)", systemImage: "hand.raised") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: Sections

    @ViewBuilder
    private func hero(_ spot: Spot) -> some View {
        if spot.status == .cleaned, let after = spot.afterPhotos.first {
            BeforeAfterSlider(before: spot.beforePhotos.first, after: after, cornerRadius: 0)
                .frame(height: 380)
        } else {
            TabView {
                ForEach(spot.beforePhotos, id: \.self) { url in
                    RemoteImage(url)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: spot.beforePhotos.count > 1 ? .always : .never))
            .frame(height: 360)
            .overlay(alignment: .bottomLeading) {
                StatusBadge(status: spot.status).padding(16)
            }
        }
    }

    private func titleBlock(_ spot: Spot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: spot.category.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(spot.category.tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(spot.category.title).font(.ccTitle).foregroundStyle(Color.ccInk)
                    HStack(spacing: 6) {
                        Label(spot.size.title, systemImage: spot.size.icon)
                        if let d = Fmt.distance(from: location.location, to: spot.location) {
                            Text("·")
                            Text("\(d) away")
                        }
                    }
                    .font(.cc(.footnote, weight: .medium)).foregroundStyle(Color.ccInk2)
                }
            }
            NavigationLink(value: Route.profile(spot.reporterId)) {
                HStack(spacing: 8) {
                    Avatar(url: spot.reporterPhoto, name: spot.reporterName, size: 26)
                    Text("Reported by \(Text(spot.reporterName).bold()) · \(Fmt.relative(spot.createdAt))")
                        .font(.cc(.footnote)).foregroundStyle(Color.ccInk2)
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func actionPanel(_ spot: Spot) -> some View {
        let me = session.uid
        switch spot.status {
        case .open:
            VStack(spacing: 10) {
                Button {
                    guard session.gate("Sign in to claim and clean this spot."), let profile = session.profile else { return }
                    run { try await SpotAPI.claim(spot, by: profile) }
                    session.show(String(localized: "Claimed! Clean it and post the after photo."), icon: "hand.raised.fill")
                } label: {
                    Label("I'll clean this", systemImage: "hand.raised.fill")
                }
                .buttonStyle(.primary)
                HStack(spacing: 10) {
                    Button {
                        if session.gate("Sign in to post a cleanup.") { showCleanup = true }
                    } label: {
                        Label("Already cleaned", systemImage: "sparkles")
                    }
                    .buttonStyle(.secondary(.ccGreen))
                    Button {
                        if session.gate("Sign in to organise a cleanup drive.") { router.startDrive(at: spot) }
                    } label: {
                        Label("Plan a drive", systemImage: "person.3.fill")
                    }
                    .buttonStyle(.secondary(.ccSaffron))
                }
                NavigationLink {
                    ComplaintView(spot: spot)
                } label: {
                    Label("Write to the municipality", systemImage: "building.columns.fill")
                }
                .buttonStyle(.secondary(.ccBlue))
            }
            .disabled(working)
        case .claimed:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "hand.raised.fill").foregroundStyle(Color.ccClaimed)
                    if spot.claimedBy == me {
                        Text("You claimed this spot. Post the after photo when it's clean.")
                    } else {
                        Text("\(Text(spot.claimedByName ?? String(localized: "Someone")).bold()) is on it. You can still help or post the cleanup.")
                    }
                }
                .font(.cc(.subheadline)).foregroundStyle(Color.ccInk)
                Button {
                    if session.gate("Sign in to post a cleanup.") { showCleanup = true }
                } label: {
                    Label("Mark as cleaned", systemImage: "sparkles")
                }
                .buttonStyle(.primary)
                if spot.claimedBy == me {
                    Button("Unclaim") { run { try await SpotAPI.unclaim(spot) } }
                        .buttonStyle(.secondary(.ccInk2))
                }
            }
            .ccCard()
            .disabled(working)
        case .cleaned:
            VStack(spacing: 10) {
                if let shareImage {
                    ShareLink(item: shareImage, message: Text(shareMessage(spot)), preview: SharePreview("Before & after", image: shareImage)) {
                        Label("Share before & after", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.primary)
                }
                if let cleanerId = spot.cleanedBy, cleanerId != me {
                    Button {
                        Task {
                            if let profile = try? await ProfileAPI.fetch(cleanerId), profile.canReceiveSupport {
                                supportProfile = profile
                            } else {
                                session.show(String(localized: "\(spot.cleanedByName ?? "They") hasn't added a UPI ID yet. Send some respect instead 🙏"), icon: "info.circle.fill")
                            }
                        }
                    } label: {
                        Label("Support \(spot.cleanedByName ?? String(localized: "the cleaner")) via UPI", systemImage: "indianrupeesign.circle.fill")
                    }
                    .buttonStyle(.secondary(.ccSaffron))
                }
            }
        }
    }

    private func reactionsRow(_ spot: Spot) -> some View {
        HStack(spacing: 10) {
            reactionButton(.respect, spot: spot, emoji: "🙏", label: "Respect", count: spot.respectCount, tint: .ccSaffron, enabled: true)
            if spot.status == .cleaned {
                reactionButton(.verified, spot: spot, emoji: "✅", label: "Verify clean", count: spot.verifiedCount, tint: .ccGreen,
                               enabled: spot.cleanedBy != session.uid)
            } else {
                reactionButton(.stillThere, spot: spot, emoji: "👀", label: "Still dirty", count: spot.stillThereCount, tint: .ccDirty,
                               enabled: spot.reporterId != session.uid)
            }
        }
    }

    private func reactionButton(_ kind: ReactionKind, spot: Spot, emoji: String, label: LocalizedStringKey, count: Int, tint: Color, enabled: Bool) -> some View {
        let active = reactions.contains(kind)
        let shown = max(count + (countDelta[kind] ?? 0), 0)
        return Button {
            guard session.gate("Sign in to react and earn points."), let uid = session.uid else { return }
            Haptics.tap()
            let newValue = !active
            if newValue { reactions.insert(kind) } else { reactions.remove(kind) }
            countDelta[kind, default: 0] += newValue ? 1 : -1
            Task {
                do {
                    try await SpotAPI.setReaction(kind, on: spot.id, uid: uid, active: newValue)
                    if newValue && kind == .verified { session.show(String(localized: "Thanks for verifying! +\(Points.verify) pts"), icon: "checkmark.seal.fill") }
                } catch {
                    if newValue { reactions.remove(kind) } else { reactions.insert(kind) }
                    countDelta[kind, default: 0] -= newValue ? 1 : -1
                    session.show(error: error)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(emoji).font(.title3)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(shown)").font(.ccNumber(17)).foregroundStyle(Color.ccInk).contentTransition(.numericText())
                    Text(label).font(.ccCaption).foregroundStyle(Color.ccInk2)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(active ? tint.opacity(0.14) : Color.ccSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(active ? tint : Color.ccStroke, lineWidth: active ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.6)
        .animation(.snappy, value: shown)
    }

    private func cleanupInfo(_ spot: Spot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let cleaner = spot.cleanedBy {
                NavigationLink(value: Route.profile(cleaner)) {
                    HStack(spacing: 12) {
                        Avatar(url: spot.cleanedByPhoto, name: spot.cleanedByName ?? "", size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cleaned by \(spot.cleanedByName ?? "")").font(.cc(.headline, weight: .bold)).foregroundStyle(Color.ccInk)
                            if let at = spot.cleanedAt {
                                Text(Fmt.relative(at)).font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Color.ccInk2)
                    }
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 10) {
                StatTile(value: "\(spot.bags)", label: "bags", icon: "bag.fill")
                StatTile(value: "\(spot.crew)", label: "people", icon: "person.2.fill", tint: .ccBlue)
                StatTile(value: "+\(Points.forCleanup(bags: spot.bags))", label: "points", icon: "leaf.fill", tint: .ccSaffron)
            }
            if let note = spot.cleanupNote {
                Text("“\(note)”").font(.cc(.subheadline)).italic().foregroundStyle(Color.ccInk)
            }
        }
    }

    private func noteBlock(_ spot: Spot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reporter's note").font(.ccCaption).foregroundStyle(Color.ccInk2)
            Text(spot.note).font(.cc(.body)).foregroundStyle(Color.ccInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ccCard()
    }

    private func locationBlock(_ spot: Spot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            MiniMap(coordinate: spot.coordinate, tint: spot.status.color, height: 150)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(spot.placeLabel).font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk)
                    Text(spot.state).font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                }
                Spacer()
                Button {
                    Directions.open(spot.coordinate, name: spot.placeLabel)
                } label: {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                }
                .buttonStyle(.secondary(.ccBlue, fullWidth: false))
            }
        }
        .ccCard(padding: 12)
    }

    private func shareMessage(_ spot: Spot) -> String {
        if spot.status == .cleaned {
            return String(localized: "Before → after at \(spot.placeLabel)! Cleaned with CleanConnect. Join in: \(AppConfig.appStoreURL.absoluteString)")
        }
        return String(localized: "This spot at \(spot.placeLabel) needs cleaning. Can you help? \(AppConfig.appStoreURL.absoluteString)")
    }

    private func run(_ work: @escaping () async throws -> Void) {
        working = true
        Task {
            do { try await work() } catch { session.show(error: error) }
            working = false
        }
    }
}

extension FlagTarget: Identifiable {
    var id: String { path }
}
