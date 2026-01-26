// DiscoverView.swift
// Central hub for discovering features: Leaderboards, Pollution Map, Badges, Live Events
// iOS 17+ with modern SwiftUI patterns - 2026

import SwiftUI

struct DiscoverView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Cleanup Jobs - Featured
                    cleanupJobsSection

                    // Featured section - Live Events
                    liveEventsSection

                    // Main feature cards
                    featureCardsSection

                    // Quick Stats
                    communityStatsSection
                }
                .padding()
            }
            .navigationTitle("Discover")
            .searchable(text: $searchText, prompt: "Search features...")
        }
    }

    // MARK: - Cleanup Jobs Section

    private var cleanupJobsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(.green)
                    Text("Cleanup Jobs")
                        .font(.headline)
                }

                Spacer()

                NavigationLink {
                    JobsMapView()
                } label: {
                    Text("View Map")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }

            // Jobs preview card
            NavigationLink {
                JobsMapView()
            } label: {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color.green.opacity(0.8), Color.teal.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Map pattern overlay
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

                    // Map pins decoration
                    HStack {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.4))
                                .offset(x: -20)
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.3))
                                .offset(x: 10)
                            Image(systemName: "mappin.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.25))
                                .offset(x: -30)
                        }
                        .padding(.trailing, 20)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Spacer()

                        HStack(spacing: 6) {
                            Image(systemName: "hand.raised.fill")
                                .font(.caption)
                            Text("Earn rewards")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(4)

                        Text("Find cleanup jobs near you")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)

                        Text("Complete jobs, post proof, earn points & tips")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))

                        // Quick stats
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "briefcase.fill")
                                Text("24 jobs nearby")
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                Text("Up to 150 pts")
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

    // MARK: - Live Events Section

    private var liveEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Live Now")
                        .font(.headline)
                }

                Spacer()

                NavigationLink {
                    OngoingEventsView()
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }

            // Live event preview card
            NavigationLink {
                OngoingEventsView()
            } label: {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color.red.opacity(0.8), Color.orange.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Spacer()

                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(4)

                        Text("Watch cleanup events as they happen")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)

                        Text("See real-time progress from events across India")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                .frame(height: 140)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Feature Cards

    private var featureCardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Explore")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                // Leaderboards
                NavigationLink {
                    LeaderboardsView()
                } label: {
                    DiscoverFeatureCard(
                        icon: "trophy.fill",
                        title: "Leaderboards",
                        subtitle: "Top contributors",
                        color: .yellow,
                        gradient: [.yellow, .orange]
                    )
                }

                // Badges
                NavigationLink {
                    BadgesView()
                } label: {
                    DiscoverFeatureCard(
                        icon: "medal.fill",
                        title: "Badges",
                        subtitle: "Your achievements",
                        color: .purple,
                        gradient: [.purple, .pink]
                    )
                }

                // Pollution Map
                NavigationLink {
                    PollutionMapView()
                } label: {
                    DiscoverFeatureCard(
                        icon: "map.fill",
                        title: "Pollution Map",
                        subtitle: "Report hotspots",
                        color: .red,
                        gradient: [.red, .orange]
                    )
                }

                // Community Stats (placeholder for future)
                NavigationLink {
                    CommunityImpactView()
                } label: {
                    DiscoverFeatureCard(
                        icon: "chart.bar.fill",
                        title: "Impact",
                        subtitle: "Community stats",
                        color: .green,
                        gradient: [.green, .teal]
                    )
                }
            }
        }
    }

    // MARK: - Community Stats Section

    private var communityStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Community Impact")
                .font(.headline)

            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    DiscoverStatCard(
                        icon: "leaf.fill",
                        value: "2.5M",
                        label: "kg waste collected",
                        color: .green
                    )

                    DiscoverStatCard(
                        icon: "person.3.fill",
                        value: "150K+",
                        label: "volunteers",
                        color: .blue
                    )
                }

                HStack(spacing: 16) {
                    DiscoverStatCard(
                        icon: "calendar.badge.checkmark",
                        value: "12K",
                        label: "events completed",
                        color: .orange
                    )

                    DiscoverStatCard(
                        icon: "indianrupeesign.circle.fill",
                        value: "₹85L",
                        label: "tips distributed",
                        color: .purple
                    )
                }
            }
        }
    }
}

// MARK: - Feature Card

struct DiscoverFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Impact Stat Card

struct DiscoverStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Community Impact View

struct CommunityImpactView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header stats
                VStack(spacing: 8) {
                    Text("2,500,000")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green)

                    Text("kg of waste collected")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("by our amazing community")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    BigStatCard(value: "150,000+", label: "Active Volunteers", icon: "person.3.fill", color: .blue)
                    BigStatCard(value: "12,000+", label: "Events Completed", icon: "calendar.badge.checkmark", color: .orange)
                    BigStatCard(value: "500+", label: "Districts Covered", icon: "map.fill", color: .purple)
                    BigStatCard(value: "₹85L+", label: "Tips Distributed", icon: "indianrupeesign.circle.fill", color: .green)
                }
                .padding(.horizontal)

                // Monthly trend
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Growth")
                        .font(.headline)

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(0..<12, id: \.self) { month in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green.opacity(0.7 + Double(month) * 0.025))
                                    .frame(width: 20, height: CGFloat(30 + month * 8))

                                Text(["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"][month])
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)

                // Top states
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Contributing States")
                        .font(.headline)

                    ForEach(topStates, id: \.0) { state, percentage in
                        HStack {
                            Text(state)
                                .font(.subheadline)

                            Spacer()

                            ProgressView(value: percentage, total: 100)
                                .frame(width: 100)
                                .tint(.green)

                            Text("\(Int(percentage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Community Impact")
        .navigationBarTitleDisplayMode(.large)
    }

    private var topStates: [(String, Double)] {
        [
            ("Maharashtra", 22),
            ("Karnataka", 18),
            ("Tamil Nadu", 15),
            ("Gujarat", 12),
            ("Delhi NCR", 10),
            ("Kerala", 8),
            ("Others", 15)
        ]
    }
}

struct BigStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.title2.bold())

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

#Preview {
    DiscoverView()
}
