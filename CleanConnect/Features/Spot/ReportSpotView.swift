import SwiftUI
import MapKit

struct ReportSpotView: View {
    @Environment(Session.self) private var session
    @Environment(LocationService.self) private var location
    @Environment(\.dismiss) private var dismiss
    @State private var draft = NewSpot()
    @State private var showPicker = false
    @State private var submitting = false
    @State private var createdId: String?
    @State private var locating = false
    @FocusState private var noteFocused: Bool

    private var canSubmit: Bool { !draft.photos.isEmpty && draft.coordinate != nil && !submitting }

    var body: some View {
        NavigationStack {
            Group {
                if let createdId {
                    ReportSuccessView(spotId: createdId, draft: draft) { dismiss() }
                } else {
                    form
                }
            }
            .background(Color.ccBackground)
        }
        .interactiveDismissDisabled(submitting)
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Report a dirty spot")
                        .font(.ccLargeTitle)
                        .foregroundStyle(Color.ccInk)
                    Text("Takes 10 seconds. Your photo goes on the city map so someone can clean it.")
                        .font(.cc(.subheadline))
                        .foregroundStyle(Color.ccInk2)
                }

                step(1, "Add a photo") {
                    PhotoStrip(photos: $draft.photos, limit: 3, tint: .ccDirty)
                    Text("Show the mess clearly. Please don't photograph people's faces.")
                        .font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                }

                step(2, "What is it?") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                        ForEach(SpotCategory.allCases) { category in
                            CategoryButton(category: category, selected: draft.category == category) {
                                draft.category = category
                            }
                        }
                    }
                }

                step(3, "How big?") {
                    HStack(spacing: 10) {
                        ForEach(SpotSize.allCases) { size in
                            Button {
                                Haptics.selection()
                                draft.size = size
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: size.icon).font(.system(size: 20, weight: .semibold))
                                    Text(size.title).font(.cc(.caption, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity, minHeight: 68)
                                .foregroundStyle(draft.size == size ? .white : Color.ccInk)
                                .background(draft.size == size ? Color.ccInk : Color.ccSurface,
                                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.ccStroke))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                step(4, "Where is it?") {
                    locationCard
                }

                step(5, "Anything else? (optional)") {
                    TextField("e.g. Behind the bus stop, been here for 2 weeks", text: $draft.note, axis: .vertical)
                        .lineLimit(2...4)
                        .focused($noteFocused)
                        .padding(14)
                        .background(Color.ccSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.ccStroke))
                }
            }
            .padding(Metrics.gutter)
            .padding(.bottom, 100)
            .readableWidth()
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button {
                submit()
            } label: {
                if submitting {
                    HStack(spacing: 10) { ProgressView().tint(.white); Text("Uploading…") }
                } else {
                    Label("Post report  ·  +\(Points.report) pts", systemImage: "paperplane.fill")
                }
            }
            .buttonStyle(.primary(.ccDirty))
            .disabled(!canSubmit)
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 10)
            .background(.bar)
            .readableWidth()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }.disabled(submitting)
            }
        }
        .sheet(isPresented: $showPicker) {
            LocationPicker(coordinate: $draft.coordinate, place: $draft.place, title: "Where is the spot?")
        }
        .task { await locate() }
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let coordinate = draft.coordinate {
                MiniMap(coordinate: coordinate, height: 130)
                    .id("\(coordinate.latitude),\(coordinate.longitude)")
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(draft.place?.label.nilIfEmpty ?? String(localized: "Pinned location"))
                            .font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk)
                        if let city = draft.place?.cityLabel.nilIfEmpty {
                            Text(city).font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                        }
                    }
                    Spacer()
                    Button("Adjust") { showPicker = true }
                        .buttonStyle(.secondary(.ccBlue, fullWidth: false))
                }
            } else if locating {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Finding your location…").font(.cc(.subheadline)).foregroundStyle(Color.ccInk2)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                VStack(spacing: 10) {
                    Text(location.isDenied ? "Location is off. Pick the spot on the map instead." : "Pick the spot on the map.")
                        .font(.cc(.subheadline)).foregroundStyle(Color.ccInk2)
                    Button {
                        showPicker = true
                    } label: {
                        Label("Choose on map", systemImage: "map.fill")
                    }
                    .buttonStyle(.secondary(.ccBlue))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .ccCard(padding: 12)
    }

    private func step<Content: View>(_ number: Int, _ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("\(number)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.ccInk, in: Circle())
                Text(title).font(.ccHeadline).foregroundStyle(Color.ccInk)
            }
            content()
        }
    }

    private func locate() async {
        guard draft.coordinate == nil else { return }
        locating = true
        location.requestPermission()
        if let current = await location.currentLocation() {
            draft.coordinate = current.coordinate
            draft.place = await location.reverseGeocode(current.coordinate)
        }
        locating = false
    }

    private func submit() {
        guard let profile = session.profile else { session.gate("Sign in to report a dirty spot."); return }
        noteFocused = false
        submitting = true
        Task {
            do {
                if draft.place == nil, let c = draft.coordinate {
                    draft.place = await location.reverseGeocode(c)
                }
                let id = try await SpotAPI.create(draft, by: profile)
                Haptics.success()
                withAnimation(.spring) { createdId = id }
            } catch {
                session.show(error: error)
            }
            submitting = false
        }
    }
}

struct CategoryButton: View {
    let category: SpotCategory
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(selected ? .white : category.tint)
                    .frame(width: 42, height: 42)
                    .background(selected ? category.tint : category.tint.opacity(0.12), in: Circle())
                Text(category.title)
                    .font(.cc(.caption, weight: .semibold))
                    .foregroundStyle(Color.ccInk)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            .padding(.horizontal, 4)
            .background(Color.ccSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(selected ? category.tint : Color.ccStroke, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct ReportSuccessView: View {
    let spotId: String
    let draft: NewSpot
    var onDone: () -> Void
    @State private var appeared = false
    @State private var shareImage: Image?

    private var shareText: String {
        let place = draft.place?.label.nilIfEmpty ?? String(localized: "my area")
        return String(localized: "Garbage spotted at \(place). Can you help clean it? It's on the CleanConnect map: \(AppConfig.appStoreURL.absoluteString)")
    }

    var body: some View {
        ZStack {
            ConfettiView().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    ZStack {
                        Circle().fill(Color.ccMint).frame(width: 120, height: 120)
                        Image(systemName: "checkmark")
                            .font(.system(size: 52, weight: .heavy))
                            .foregroundStyle(Color.ccGreen)
                            .scaleEffect(appeared ? 1 : 0.3)
                    }
                    .padding(.top, 40)
                    VStack(spacing: 8) {
                        Text("Reported! Thank you 🙏").font(.ccTitle).foregroundStyle(Color.ccInk)
                        Text("+\(Points.report) Swachh Points").font(.ccNumber(18)).foregroundStyle(Color.ccGreen)
                        Text("It's live on the map. Spots that get shared get cleaned much faster.")
                            .font(.cc(.subheadline)).foregroundStyle(Color.ccInk2).multilineTextAlignment(.center)
                    }
                    if let photo = draft.photos.first {
                        Image(uiImage: photo)
                            .resizable().scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    VStack(spacing: 10) {
                        if let shareImage {
                            ShareLink(item: shareImage, subject: Text("Help clean this spot"), message: Text(shareText),
                                      preview: SharePreview("Help clean this spot", image: shareImage)) {
                                Label("Share on WhatsApp & more", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.primary)
                        }
                        NavigationLink {
                            ComplaintView(spot: nil, draft: draft)
                        } label: {
                            Label("Write to the municipality", systemImage: "building.columns.fill")
                        }
                        .buttonStyle(.secondary(.ccBlue))
                        Button("Done", action: onDone)
                            .buttonStyle(.secondary(.ccInk2))
                    }
                }
                .padding(Metrics.gutter)
                .readableWidth(560)
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true }
            if let photo = draft.photos.first {
                shareImage = ShareCards.reportCard(photo: photo, category: draft.category, place: draft.place?.label ?? "")
            }
        }
    }
}
