import SwiftUI

struct MyProfileView: View {
    @Environment(Session.self) private var session

    var body: some View {
        Group {
            if let profile = session.profile {
                ProfileContent(profile: profile, isMe: true)
            } else {
                guestView
            }
        }
        .background(Color.ccBackground)
        .navigationTitle("You")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: Route.settings) { Image(systemName: "gearshape.fill") }
                    .accessibilityLabel(Text("Settings"))
            }
        }
    }

    private var guestView: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image("BrandMark").resizable().frame(width: 96, height: 96)
                    .shadow(color: Color.ccGreen.opacity(0.35), radius: 16, y: 8)
                    .padding(.top, 30)
                Text("Your Swachh profile").font(.ccTitle).foregroundStyle(Color.ccInk)
                Text("Sign in to track your cleanups, earn points and badges, keep a streak and climb your city's leaderboard.")
                    .font(.cc(.subheadline)).foregroundStyle(Color.ccInk2).multilineTextAlignment(.center)
                Button("Sign in") { session.gate("Sign in to start your Swachh profile.") }
                    .buttonStyle(.primary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 12) {
                    ForEach(Badge.allCases.prefix(6)) { badge in
                        BadgeView(badge: badge, earned: false)
                    }
                }
                .padding(.top, 8)
            }
            .padding(24)
            .readableWidth(520)
        }
    }
}

struct PublicProfileView: View {
    let uid: String
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var profile: Profile?
    @State private var loaded = false
    @State private var flag: FlagTarget?

    var body: some View {
        Group {
            if let profile {
                ProfileContent(profile: profile, isMe: profile.id == session.uid)
            } else if loaded {
                EmptyStateView(icon: "person.crop.circle.badge.questionmark", title: "Profile not found", message: "This account may have been deleted.")
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.ccBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if session.isSignedIn, uid != session.uid {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { flag = .profile(uid) } label: { Label("Report profile", systemImage: "flag") }
                        if session.isBlocked(uid) {
                            Button { Task { await session.unblock(uid) } } label: { Label("Unblock", systemImage: "hand.raised.slash") }
                        } else {
                            Button(role: .destructive) {
                                Task { await session.block(uid); dismiss() }
                            } label: { Label("Block", systemImage: "hand.raised") }
                        }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
        }
        .sheet(item: $flag) { FlagSheet(target: $0) }
        .task {
            for await value in ProfileAPI.profile(uid) {
                profile = value
                loaded = true
            }
        }
    }
}

struct ProfileContent: View {
    let profile: Profile
    let isMe: Bool

    enum Tab: String, CaseIterable, Identifiable {
        case cleanups, reports, drives
        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .cleanups: "Cleanups"
            case .reports: "Reports"
            case .drives: "Drives"
            }
        }
    }

    @Environment(Session.self) private var session
    @Environment(LocationService.self) private var location
    @State private var tab: Tab = .cleanups
    @State private var cleaned: [Spot] = []
    @State private var reported: [Spot] = []
    @State private var drives: [Drive] = []
    @State private var showEdit = false
    @State private var showSupport = false
    @State private var selectedBadge: Badge?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                if isMe && profile.upiId == nil { upiPrompt }
                if !isMe && profile.canReceiveSupport {
                    Button { showSupport = true } label: {
                        Label("Support \(profile.firstName) via UPI", systemImage: "indianrupeesign.circle.fill")
                    }
                    .buttonStyle(.primary(.ccSaffron))
                }
                levelCard
                statsGrid
                badgesSection
                activitySection
            }
            .padding(Metrics.gutter)
            .padding(.bottom, 40)
            .readableWidth()
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack { EditProfileView(profile: profile) }
        }
        .sheet(isPresented: $showSupport) { SupportSheet(recipient: profile, context: .cleanup) }
        .sheet(item: $selectedBadge) { badge in
            VStack(spacing: 14) {
                BadgeView(badge: badge, earned: badge.isEarned(by: profile), size: 96)
                Text(badge.title).font(.ccTitle).foregroundStyle(Color.ccInk)
                Text(badge.detail).font(.cc(.body)).foregroundStyle(Color.ccInk2)
                Text(badge.isEarned(by: profile) ? "Unlocked ✨" : "Locked. Keep going!")
                    .font(.cc(.subheadline, weight: .bold))
                    .foregroundStyle(badge.isEarned(by: profile) ? Color.ccGreen : Color.ccInk2)
            }
            .padding(30)
            .presentationDetents([.height(320)])
        }
        .task(id: profile.id) {
            async let c = (try? await SpotAPI.cleaned(by: profile.id)) ?? []
            async let r = (try? await SpotAPI.reported(by: profile.id)) ?? []
            async let h = (try? await DriveAPI.hosted(by: profile.id)) ?? []
            (cleaned, reported, drives) = await (c, r, h)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Avatar(url: profile.photoURL, name: profile.name, size: 104)
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                Image(systemName: profile.level.icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(profile.level.color, in: Circle())
                    .overlay(Circle().strokeBorder(Color.ccBackground, lineWidth: 3))
            }
            VStack(spacing: 4) {
                Text(profile.name).font(.ccTitle).foregroundStyle(Color.ccInk)
                HStack(spacing: 6) {
                    Text(profile.level.title).foregroundStyle(profile.level.color).fontWeight(.bold)
                    if !profile.placeLabel.isEmpty {
                        Text("·")
                        Label(profile.placeLabel, systemImage: "mappin")
                    }
                }
                .font(.cc(.subheadline)).foregroundStyle(Color.ccInk2)
                if !profile.bio.isEmpty {
                    Text(profile.bio).font(.cc(.subheadline)).foregroundStyle(Color.ccInk).multilineTextAlignment(.center).padding(.top, 4)
                }
                if let insta = profile.instagram, let url = URL(string: "https://instagram.com/\(insta)") {
                    Link(destination: url) { Label("@\(insta)", systemImage: "camera.circle.fill") }
                        .font(.cc(.footnote, weight: .semibold)).padding(.top, 2)
                }
            }
            if isMe {
                Button { showEdit = true } label: { Label("Edit profile", systemImage: "pencil") }
                    .buttonStyle(.secondary(.ccInk, fullWidth: false))
            }
        }
    }

    private var upiPrompt: some View {
        Button { showEdit = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "indianrupeesign.circle.fill").font(.title).foregroundStyle(Color.ccSaffron)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add your UPI ID").font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk)
                    Text("Let people thank you for cleanups. 100% goes to you, and we take nothing.")
                        .font(.cc(.caption)).foregroundStyle(Color.ccInk2).multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Color.ccInk2)
            }
            .padding(14)
            .background(Color.ccSaffronSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.pressable)
    }

    private var levelCard: some View {
        let level = profile.level
        return HStack(spacing: 14) {
            LevelRing(progress: level.progress(points: profile.points), level: level, size: 62)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(profile.points.formatted()).font(.ccNumber(28)).foregroundStyle(Color.ccInk)
                    Text("Swachh Points").font(.ccCaption).foregroundStyle(Color.ccInk2)
                }
                if let next = level.next {
                    ProgressView(value: level.progress(points: profile.points)).tint(level.color)
                    Text("\(next.minPoints - profile.points) to \(Text(next.title))").font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                }
            }
            if profile.liveStreak > 0 {
                VStack(spacing: 0) {
                    Text("🔥").font(.title2)
                    Text("\(profile.liveStreak)").font(.ccNumber(18)).foregroundStyle(Color.ccSaffron)
                    Text("day streak").font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(Color.ccInk2)
                }
            }
        }
        .ccCard()
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            StatTile(value: "\(profile.cleanups)", label: "cleanups", icon: "sparkles", tint: .ccGreen)
            StatTile(value: "\(profile.reports)", label: "reports", icon: "camera.fill", tint: .ccDirty)
            StatTile(value: "\(profile.bags)", label: "bags", icon: "bag.fill", tint: Color(hex: 0x8A6E52))
            StatTile(value: "\(profile.drivesHosted)", label: "drives led", icon: "flag.fill", tint: .ccSaffron)
            StatTile(value: "\(profile.drivesJoined)", label: "drives joined", icon: "person.3.fill", tint: .ccSaffron)
            StatTile(value: "\(profile.verifications)", label: "verified", icon: "checkmark.seal.fill", tint: Color(hex: 0x7C5CDB))
        }
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Badges", subtitle: "\(profile.badges.count) of \(Badge.allCases.count) unlocked")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 10)], spacing: 14) {
                ForEach(Badge.allCases) { badge in
                    Button { selectedBadge = badge } label: {
                        VStack(spacing: 6) {
                            BadgeView(badge: badge, earned: badge.isEarned(by: profile))
                            Text(badge.title).font(.cc(.caption2, weight: .semibold)).foregroundStyle(Color.ccInk)
                                .multilineTextAlignment(.center).lineLimit(2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .ccCard()
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Activity", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            switch tab {
            case .cleanups:
                if cleaned.isEmpty {
                    EmptyStateView(icon: "sparkles", title: "No cleanups yet", message: isMe ? "Find a dirty spot near you and turn it green." : "Nothing here yet.")
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(cleaned) { spot in
                            NavigationLink(value: Route.spot(spot.id)) {
                                BeforeAfterThumb(spot: spot)
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                }
            case .reports:
                if reported.isEmpty {
                    EmptyStateView(icon: "camera.fill", title: "No reports yet", message: isMe ? "Spotted garbage? Snap it and put it on the map." : "Nothing here yet.")
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(reported) { spot in
                            NavigationLink(value: Route.spot(spot.id)) { SpotRow(spot: spot, origin: location.location) }
                                .buttonStyle(.pressable)
                        }
                    }
                }
            case .drives:
                if drives.isEmpty {
                    EmptyStateView(icon: "flag.fill", title: "No drives organised", message: isMe ? "Rally your neighbours for a cleanup." : "Nothing here yet.")
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(drives) { drive in
                            NavigationLink(value: Route.drive(drive.id)) { DriveCard(drive: drive, origin: location.location, width: nil) }
                                .buttonStyle(.pressable)
                        }
                    }
                }
            }
        }
    }
}

struct BeforeAfterThumb: View {
    let spot: Spot

    var body: some View {
        HStack(spacing: 2) {
            RemoteImage(spot.beforePhotos.first)
            RemoteImage(spot.afterPhotos.first)
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            Text(spot.locality.nilIfEmpty ?? spot.city)
                .font(.cc(.caption2, weight: .bold)).foregroundStyle(.white).lineLimit(1)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(.black.opacity(0.5), in: Capsule())
                .padding(6)
        }
    }
}

struct BadgeView: View {
    let badge: Badge
    let earned: Bool
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle()
                .fill(earned ? AnyShapeStyle(LinearGradient(colors: [badge.color.opacity(0.85), badge.color], startPoint: .top, endPoint: .bottom))
                      : AnyShapeStyle(Color.ccSurface2))
                .frame(width: size, height: size)
                .overlay(Circle().strokeBorder(earned ? Color.white.opacity(0.5) : Color.ccStroke, lineWidth: 2))
                .shadow(color: earned ? badge.color.opacity(0.35) : .clear, radius: 6, y: 3)
            Image(systemName: earned ? badge.icon : "lock.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(earned ? Color.white : Color.ccInk2.opacity(0.5))
        }
        .accessibilityLabel(Text(badge.title))
        .accessibilityValue(Text(earned ? "Unlocked" : "Locked"))
    }
}
