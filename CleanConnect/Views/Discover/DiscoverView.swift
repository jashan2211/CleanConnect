// DiscoverView.swift
// Central hub for discovering features and community events
// iOS 17+ with modern SwiftUI patterns - 2026

import SwiftUI

struct DiscoverView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Featured: Upcoming Events
                    upcomingEventsSection

                    // Coming Soon features
                    comingSoonSection
                }
                .padding()
            }
            .navigationTitle("Discover")
            .searchable(text: $searchText, prompt: "Search...")
        }
    }

    // MARK: - Upcoming Events Section

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.green)
                    Text("Cleanup Events")
                        .font(.headline)
                }

                Spacer()

                NavigationLink {
                    GatheringsView()
                } label: {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }

            // Events preview card
            NavigationLink {
                GatheringsView()
            } label: {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color.green.opacity(0.8), Color.teal.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Decorative pattern
                    GeometryReader { geo in
                        Path { path in
                            for i in stride(from: 0, to: geo.size.width, by: 30) {
                                path.move(to: CGPoint(x: i, y: 0))
                                path.addLine(to: CGPoint(x: i, y: geo.size.height))
                            }
                            for i in stride(from: 0, to: geo.size.height, by: 30) {
                                path.move(to: CGPoint(x: 0, y: i))
                                path.addLine(to: CGPoint(x: geo.size.width, y: i))
                            }
                        }
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }

                    // Calendar icons decoration
                    HStack {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "person.3.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.4))
                                .offset(x: -20)
                            Image(systemName: "leaf.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.3))
                                .offset(x: 10)
                            Image(systemName: "hands.sparkles.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.25))
                                .offset(x: -30)
                        }
                        .padding(.trailing, 20)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Spacer()

                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                            Text("Join the movement")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(4)

                        Text("Community Cleanup Events")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)

                        Text("Join or organize cleanup drives in your area")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))

                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text("Upcoming events")
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                Text("Earn points")
                            }
                        }
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 4)
                    }
                    .padding()
                }
                .frame(height: 180)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Coming Soon Section

    private var comingSoonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Coming Soon")
                .font(.headline)

            VStack(spacing: 12) {
                ComingSoonCard(
                    icon: "trophy.fill",
                    title: "Leaderboards",
                    description: "Compete with top contributors across India",
                    color: .yellow
                )

                ComingSoonCard(
                    icon: "medal.fill",
                    title: "Badges & Achievements",
                    description: "Earn badges for your cleanup milestones",
                    color: .purple
                )

                ComingSoonCard(
                    icon: "map.fill",
                    title: "Pollution Hotspot Map",
                    description: "Report and track pollution in your area",
                    color: .red
                )

                ComingSoonCard(
                    icon: "briefcase.fill",
                    title: "Cleanup Jobs",
                    description: "Find paid cleanup opportunities nearby",
                    color: .blue
                )
            }
        }
    }
}

// MARK: - Coming Soon Card

struct ComingSoonCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))

                    Text("SOON")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray)
                        .cornerRadius(4)
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    DiscoverView()
}
