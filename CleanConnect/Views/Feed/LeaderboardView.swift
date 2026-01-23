// LeaderboardView.swift
// Global and local leaderboard rankings

import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var selectedScope: LeaderboardScope = .global

    enum LeaderboardScope: String, CaseIterable {
        case global = "Global"
        case state = "State"
        case district = "District"
        case city = "City"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Scope selector
            Picker("Scope", selection: $selectedScope) {
                ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: selectedScope) { _, newScope in
                viewModel.loadLeaderboard(scope: newScope)
            }

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Top 3 podium
                        if viewModel.entries.count >= 3 {
                            podiumView
                                .padding(.bottom, 24)
                        }

                        // Rest of leaderboard
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                                if index >= 3 {
                                    LeaderboardRow(rank: index + 1, entry: entry)
                                    if index < viewModel.entries.count - 1 {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadLeaderboard(scope: selectedScope)
        }
    }

    private var podiumView: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // 2nd place
            if viewModel.entries.count > 1 {
                PodiumCard(rank: 2, entry: viewModel.entries[1], height: 100)
            }

            // 1st place
            if viewModel.entries.count > 0 {
                PodiumCard(rank: 1, entry: viewModel.entries[0], height: 130)
            }

            // 3rd place
            if viewModel.entries.count > 2 {
                PodiumCard(rank: 3, entry: viewModel.entries[2], height: 80)
            }
        }
    }
}

struct PodiumCard: View {
    let rank: Int
    let entry: LeaderboardEntry
    let height: CGFloat

    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(hex: "C0C0C0") // Silver
        case 3: return Color(hex: "CD7F32") // Bronze
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Crown for 1st place
            if rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
            }

            // Avatar
            AsyncImage(url: URL(string: entry.photoURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
            }
            .frame(width: rank == 1 ? 70 : 56, height: rank == 1 ? 70 : 56)
            .clipShape(Circle())
            .overlay(Circle().stroke(rankColor, lineWidth: 3))

            // Name
            Text(entry.displayName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            // Points
            Text("\(entry.points) pts")
                .font(.caption2)
                .foregroundColor(.secondary)

            // Rank badge
            Text("#\(rank)")
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(rankColor)
                .clipShape(Circle())
        }
        .frame(maxWidth: .infinity)
        .frame(height: height + 100)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("\(rank)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30)

            // Avatar
            AsyncImage(url: URL(string: entry.photoURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            // Name and level
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text(entry.level)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Points
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.points)")
                    .font(.headline)
                    .foregroundColor(.green)
                Text("points")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
}
