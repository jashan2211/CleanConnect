import SwiftUI

struct LeaderboardView: View {
    enum Scope: String, CaseIterable, Identifiable {
        case city, state, india
        var id: String { rawValue }
    }

    @Environment(Session.self) private var session
    @Environment(LocationService.self) private var location
    @State private var period: LeaderboardPeriod = .week
    @State private var scope: Scope = .india
    @State private var rows: [Profile] = []
    @State private var loading = true
    @State private var showHowTo = false

    private var city: String { session.profile?.city.nilIfEmpty ?? location.place?.city ?? "" }
    private var state: String { session.profile?.state.nilIfEmpty ?? location.place?.state ?? "" }

    private var query: LeaderboardScope {
        switch scope {
        case .india: .india
        case .state: state.isEmpty ? .india : .state(state)
        case .city: city.isEmpty ? .india : .city(key: CityKey.make(city: city, state: state), name: city)
        }
    }

    private func score(_ p: Profile) -> Int { period == .week ? p.thisWeekPoints : p.points }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Picker("Period", selection: $period) {
                    Text("This week").tag(LeaderboardPeriod.week)
                    Text("All time").tag(LeaderboardPeriod.allTime)
                }
                .pickerStyle(.segmented)

                HStack(spacing: 8) {
                    Chip(title: city.isEmpty ? "My city" : LocalizedStringKey(city), icon: "building.2.fill", isSelected: scope == .city) { scope = .city }
                    Chip(title: state.isEmpty ? "My state" : LocalizedStringKey(state), icon: "map.fill", isSelected: scope == .state) { scope = .state }
                    Chip(title: "India", icon: "flag.fill", isSelected: scope == .india) { scope = .india }
                    Spacer(minLength: 0)
                }

                if loading && rows.isEmpty {
                    ProgressView().padding(40)
                } else if rows.isEmpty {
                    EmptyStateView(icon: "trophy.fill", title: "The podium is empty",
                                   message: period == .week ? "No points yet this week. Report or clean a spot to take #1." : "Report or clean a spot to get on the board.")
                        .ccCard(padding: 0)
                } else {
                    podium
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated().dropFirst(3)), id: \.element.id) { index, profile in
                            NavigationLink(value: Route.profile(profile.id)) {
                                row(rank: index + 1, profile: profile)
                            }
                            .buttonStyle(.plain)
                            if index < rows.count - 1 { Divider().padding(.leading, 60) }
                        }
                    }
                    .ccCard(padding: 8)
                }

                Button { showHowTo = true } label: {
                    Label("How to earn Swachh Points", systemImage: "info.circle.fill")
                }
                .buttonStyle(.secondary(.ccGreen))
            }
            .padding(Metrics.gutter)
            .padding(.bottom, 90)
            .readableWidth()
        }
        .background(Color.ccBackground)
        .navigationTitle("Leaderboard")
        .safeAreaInset(edge: .bottom) { myRank }
        .refreshable { await load() }
        .task(id: "\(period.rawValue)-\(scope.rawValue)-\(city)") { await load() }
        .sheet(isPresented: $showHowTo) { HowToEarnSheet() }
    }

    private func load() async {
        loading = true
        do {
            rows = try await ProfileAPI.leaderboard(period: period, scope: query).filter { !session.isBlocked($0.id) }
        } catch {
            print("Leaderboard error:", error)
            rows = []
        }
        loading = false
    }

    private var podium: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if rows.count > 1 { podiumColumn(rows[1], rank: 2, height: 96) }
            podiumColumn(rows[0], rank: 1, height: 130)
            if rows.count > 2 { podiumColumn(rows[2], rank: 3, height: 76) }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }

    private func podiumColumn(_ profile: Profile, rank: Int, height: CGFloat) -> some View {
        let colors: [Color] = [Color(hex: 0xF5B400), Color(hex: 0xA8B2BD), Color(hex: 0xCD7F32)]
        return NavigationLink(value: Route.profile(profile.id)) {
            VStack(spacing: 6) {
                ZStack(alignment: .top) {
                    Avatar(url: profile.photoURL, name: profile.name, size: rank == 1 ? 76 : 60)
                        .overlay(Circle().strokeBorder(colors[rank - 1], lineWidth: 3))
                        .padding(.top, rank == 1 ? 18 : 0)
                    if rank == 1 {
                        Image(systemName: "crown.fill").font(.system(size: 22)).foregroundStyle(colors[0])
                    }
                }
                Text(profile.firstName).font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk).lineLimit(1)
                Text("\(score(profile))").font(.ccNumber(15)).foregroundStyle(Color.ccGreen)
                ZStack(alignment: .top) {
                    UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14)
                        .fill(LinearGradient(colors: [colors[rank - 1].opacity(0.9), colors[rank - 1].opacity(0.55)], startPoint: .top, endPoint: .bottom))
                    Text("\(rank)").font(.system(size: 30, weight: .heavy, design: .rounded)).foregroundStyle(.white).padding(.top, 8)
                }
                .frame(height: height)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func row(rank: Int, profile: Profile) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)").font(.ccNumber(15)).foregroundStyle(Color.ccInk2).frame(width: 30)
            Avatar(url: profile.photoURL, name: profile.name, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(profile.name).font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk).lineLimit(1)
                    if profile.id == session.uid { Text("(you)").font(.cc(.caption)).foregroundStyle(Color.ccInk2) }
                }
                HStack(spacing: 4) {
                    Image(systemName: profile.level.icon).foregroundStyle(profile.level.color)
                    Text(profile.level.title)
                    if !profile.city.isEmpty { Text("· \(profile.city)") }
                }
                .font(.cc(.caption)).foregroundStyle(Color.ccInk2).lineLimit(1)
            }
            Spacer()
            Text("\(score(profile))").font(.ccNumber(17)).foregroundStyle(Color.ccGreen)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(profile.id == session.uid ? Color.ccMint : .clear, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var myRank: some View {
        if let me = session.profile, !rows.isEmpty {
            let rank = rows.firstIndex { $0.id == me.id }.map { $0 + 1 }
            HStack(spacing: 12) {
                Avatar(url: me.photoURL, name: me.name, size: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text(rank.map { String(localized: "You're #\($0)") } ?? String(localized: "You're not on this board yet"))
                        .font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk)
                    Text(period == .week ? "\(me.thisWeekPoints) points this week" : "\(me.points) points all time")
                        .font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                }
                Spacer()
                Image(systemName: me.level.icon).foregroundStyle(me.level.color).font(.title3)
            }
            .padding(12)
            .ccGlass(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 6)
            .readableWidth()
        }
    }
}

struct HowToEarnSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Earn Swachh Points") {
                    earn("camera.fill", .ccDirty, "Report a dirty spot", Points.report)
                    earn("sparkles", .ccGreen, "Clean a spot (+5 per bag, up to 20 bags)", Points.cleanup)
                    earn("checkmark.circle.fill", .ccBlue, "Your report gets cleaned", Points.reportGotCleaned)
                    earn("checkmark.seal.fill", Color(hex: 0x7C5CDB), "Verify someone's cleanup", Points.verify)
                    earn("person.3.fill", .ccSaffron, "Join a cleanup drive", Points.joinDrive)
                    earn("flag.fill", .ccSaffron, "Organise a drive", Points.hostDrive)
                    earn("flag.checkered", .ccSaffron, "Complete your drive (+5 per bag)", Points.completeDrive)
                }
                Section("Levels") {
                    ForEach(Level.all) { level in
                        HStack(spacing: 12) {
                            Image(systemName: level.icon).foregroundStyle(level.color).frame(width: 28)
                            Text(level.title)
                            Spacer()
                            Text("\(level.minPoints)+").font(.ccNumber(15)).foregroundStyle(Color.ccInk2)
                        }
                    }
                }
                Section {
                    Text("Weekly boards reset every Monday (IST). Help out on consecutive days to build your streak 🔥")
                        .font(.cc(.footnote)).foregroundStyle(Color.ccInk2)
                }
            }
            .navigationTitle("How it works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.large])
    }

    private func earn(_ icon: String, _ tint: Color, _ title: LocalizedStringKey, _ points: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(tint).frame(width: 28)
            Text(title)
            Spacer()
            Text("+\(points)").font(.ccNumber(15)).foregroundStyle(Color.ccGreen)
        }
    }
}
