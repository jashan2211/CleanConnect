// ImpactDashboardView.swift
// Comprehensive impact visualization - iOS 17+
// Visual equivalents, community milestones, personal journey, live map

import SwiftUI
import MapKit
import Observation

// MARK: - Impact Dashboard View Model

@MainActor
@Observable
class ImpactDashboardViewModel {
    // Personal stats
    var totalWasteKg: Double = 127.5
    var totalCleanups: Int = 34
    var totalHours: Int = 52
    var currentStreak: Int = 7
    var treesEquivalent: Int = 0
    var bottlesEquivalent: Int = 0
    var bagsEquivalent: Int = 0
    var co2Saved: Double = 0

    // Community stats
    var cityWasteKg: Double = 45000
    var cityCleanups: Int = 1250
    var cityVolunteers: Int = 3400
    var stateWasteKg: Double = 890000
    var nationalWasteKg: Double = 2500000

    // Milestones
    var communityMilestones: [CommunityMilestone] = []
    var personalMilestones: [PersonalMilestone] = []

    // Live activity
    var recentCleanups: [LiveCleanupActivity] = []

    // Journey
    var journeyItems: [JourneyItem] = []

    func loadData() async {
        // Calculate visual equivalents
        calculateEquivalents()

        // Load milestones
        loadMilestones()

        // Load journey
        loadJourney()

        // Load live activity
        loadLiveActivity()
    }

    private func calculateEquivalents() {
        // 1 plastic bottle = ~25g
        bottlesEquivalent = Int(totalWasteKg * 1000 / 25)

        // 1 large garbage bag = ~5kg
        bagsEquivalent = Int(totalWasteKg / 5)

        // Rough estimate: 1kg plastic waste properly recycled saves ~2kg CO2
        co2Saved = totalWasteKg * 2

        // 1 tree absorbs ~22kg CO2/year, so this is a fraction
        treesEquivalent = Int(co2Saved / 22)
    }

    private func loadMilestones() {
        communityMilestones = [
            CommunityMilestone(
                id: "m1",
                title: "Mumbai 50 Ton Challenge",
                description: "Collect 50,000 kg of waste across Mumbai",
                targetKg: 50000,
                currentKg: 45000,
                reward: "Unlock exclusive Mumbai Warrior badge",
                deadline: Date().addingTimeInterval(86400 * 14),
                participantCount: 3400,
                isCompleted: false
            ),
            CommunityMilestone(
                id: "m2",
                title: "Beach Week Special",
                description: "Clean 100 beaches across India this week",
                targetKg: 25000,
                currentKg: 18500,
                reward: "All participants get 2x points next week",
                deadline: Date().addingTimeInterval(86400 * 3),
                participantCount: 890,
                isCompleted: false
            ),
            CommunityMilestone(
                id: "m3",
                title: "Diwali Clean Drive",
                description: "Pre-Diwali city cleanup campaign",
                targetKg: 100000,
                currentKg: 100000,
                reward: "Community celebration event",
                deadline: Date().addingTimeInterval(-86400 * 30),
                participantCount: 8500,
                isCompleted: true
            )
        ]

        personalMilestones = [
            PersonalMilestone(id: "p1", title: "First Cleanup", description: "Complete your first cleanup", isCompleted: true, completedAt: Date().addingTimeInterval(-86400 * 60), icon: "leaf.fill", points: 50),
            PersonalMilestone(id: "p2", title: "10 Cleanups", description: "Complete 10 cleanups", isCompleted: true, completedAt: Date().addingTimeInterval(-86400 * 30), icon: "leaf.circle.fill", points: 100),
            PersonalMilestone(id: "p3", title: "50kg Warrior", description: "Collect 50kg total waste", isCompleted: true, completedAt: Date().addingTimeInterval(-86400 * 20), icon: "scalemass.fill", points: 150),
            PersonalMilestone(id: "p4", title: "100kg Champion", description: "Collect 100kg total waste", isCompleted: true, completedAt: Date().addingTimeInterval(-86400 * 5), icon: "trophy.fill", points: 300),
            PersonalMilestone(id: "p5", title: "Week Warrior", description: "7-day cleanup streak", isCompleted: true, completedAt: Date(), icon: "flame.fill", points: 200),
            PersonalMilestone(id: "p6", title: "500kg Legend", description: "Collect 500kg total waste", isCompleted: false, completedAt: nil, icon: "star.fill", points: 1000)
        ]
    }

    private func loadJourney() {
        journeyItems = [
            JourneyItem(id: "j1", date: Date().addingTimeInterval(-86400 * 60), title: "Started my journey", description: "First cleanup at local park", wasteKg: 2.5, location: "Cubbon Park, Bangalore", imageURL: nil, type: .firstCleanup),
            JourneyItem(id: "j2", date: Date().addingTimeInterval(-86400 * 45), title: "Joined community event", description: "Beach cleanup with 50 volunteers", wasteKg: 8.0, location: "Juhu Beach, Mumbai", imageURL: nil, type: .event),
            JourneyItem(id: "j3", date: Date().addingTimeInterval(-86400 * 30), title: "10 cleanups milestone", description: "Reached double digits!", wasteKg: 0, location: nil, imageURL: nil, type: .milestone),
            JourneyItem(id: "j4", date: Date().addingTimeInterval(-86400 * 20), title: "50kg collected", description: "Major milestone achieved", wasteKg: 0, location: nil, imageURL: nil, type: .milestone),
            JourneyItem(id: "j5", date: Date().addingTimeInterval(-86400 * 10), title: "First tip received", description: "Someone appreciated my work!", wasteKg: 0, location: nil, imageURL: nil, type: .tip),
            JourneyItem(id: "j6", date: Date().addingTimeInterval(-86400 * 5), title: "100kg champion", description: "Three-digit warrior now!", wasteKg: 0, location: nil, imageURL: nil, type: .milestone),
            JourneyItem(id: "j7", date: Date(), title: "7-day streak", description: "Cleanup every day this week", wasteKg: 15.5, location: "Various locations", imageURL: nil, type: .streak)
        ]
    }

    private func loadLiveActivity() {
        recentCleanups = [
            LiveCleanupActivity(id: "l1", userName: "Rahul S.", location: "Marine Drive, Mumbai", wasteKg: 3.2, timeAgo: "2 min ago", latitude: 18.9432, longitude: 72.8235),
            LiveCleanupActivity(id: "l2", userName: "Priya M.", location: "Lodhi Garden, Delhi", wasteKg: 2.1, timeAgo: "5 min ago", latitude: 28.5933, longitude: 77.2190),
            LiveCleanupActivity(id: "l3", userName: "Amit K.", location: "Cubbon Park, Bangalore", wasteKg: 4.5, timeAgo: "8 min ago", latitude: 12.9763, longitude: 77.5929),
            LiveCleanupActivity(id: "l4", userName: "Sneha R.", location: "Marina Beach, Chennai", wasteKg: 5.0, timeAgo: "12 min ago", latitude: 13.0500, longitude: 80.2824),
            LiveCleanupActivity(id: "l5", userName: "Vikram P.", location: "Sabarmati, Ahmedabad", wasteKg: 2.8, timeAgo: "15 min ago", latitude: 23.0225, longitude: 72.5714)
        ]
    }
}

// MARK: - Data Models

struct CommunityMilestone: Identifiable {
    let id: String
    let title: String
    let description: String
    let targetKg: Double
    let currentKg: Double
    let reward: String
    let deadline: Date
    let participantCount: Int
    let isCompleted: Bool

    var progress: Double {
        min(currentKg / targetKg, 1.0)
    }
}

struct PersonalMilestone: Identifiable {
    let id: String
    let title: String
    let description: String
    let isCompleted: Bool
    let completedAt: Date?
    let icon: String
    let points: Int
}

struct JourneyItem: Identifiable {
    let id: String
    let date: Date
    let title: String
    let description: String
    let wasteKg: Double
    let location: String?
    let imageURL: String?
    let type: JourneyType

    enum JourneyType {
        case firstCleanup, cleanup, event, milestone, tip, streak
    }
}

struct LiveCleanupActivity: Identifiable {
    let id: String
    let userName: String
    let location: String
    let wasteKg: Double
    let timeAgo: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Impact Dashboard View

struct ImpactDashboardView: View {
    @State private var viewModel = ImpactDashboardViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Tab selector
                    Picker("View", selection: $selectedTab) {
                        Text("My Impact").tag(0)
                        Text("Community").tag(1)
                        Text("Journey").tag(2)
                        Text("Live Map").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    switch selectedTab {
                    case 0:
                        personalImpactView
                    case 1:
                        communityImpactView
                    case 2:
                        journeyTimelineView
                    case 3:
                        liveMapView
                    default:
                        EmptyView()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Your Impact")
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Personal Impact View

    private var personalImpactView: some View {
        VStack(spacing: 20) {
            // Main stat
            VStack(spacing: 8) {
                Text("\(String(format: "%.1f", viewModel.totalWasteKg))")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.green)

                Text("kg of waste collected")
                    .font(.title3)
                    .foregroundColor(.secondary)

                Text("in \(viewModel.totalCleanups) cleanups over \(viewModel.totalHours) hours")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)

            // Visual equivalents
            VStack(alignment: .leading, spacing: 16) {
                Text("That's equivalent to...")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        EquivalentCard(
                            icon: "waterbottle.fill",
                            value: "\(viewModel.bottlesEquivalent)",
                            label: "plastic bottles",
                            color: .blue
                        )

                        EquivalentCard(
                            icon: "bag.fill",
                            value: "\(viewModel.bagsEquivalent)",
                            label: "garbage bags",
                            color: .orange
                        )

                        EquivalentCard(
                            icon: "tree.fill",
                            value: "\(viewModel.treesEquivalent)",
                            label: "trees worth of CO2",
                            color: .green
                        )

                        EquivalentCard(
                            icon: "cloud.fill",
                            value: "\(String(format: "%.0f", viewModel.co2Saved))",
                            label: "kg CO2 saved",
                            color: .cyan
                        )
                    }
                    .padding(.horizontal)
                }
            }

            // Streak
            if viewModel.currentStreak > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.currentStreak) day streak!")
                            .font(.headline)
                        Text("Keep going!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Streak days visualization
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { day in
                            Circle()
                                .fill(day < viewModel.currentStreak ? Color.orange : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
            }

            // Personal milestones
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Milestones")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(viewModel.personalMilestones) { milestone in
                    PersonalMilestoneRow(milestone: milestone)
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Community Impact View

    private var communityImpactView: some View {
        VStack(spacing: 20) {
            // National stats
            VStack(spacing: 8) {
                Text("India's Impact")
                    .font(.headline)

                HStack(spacing: 20) {
                    StatBubble(value: "2.5M", label: "kg collected", color: .green)
                    StatBubble(value: "150K", label: "volunteers", color: .blue)
                    StatBubble(value: "12K", label: "cleanups", color: .orange)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal)

            // Your city
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Mumbai")
                        .font(.headline)
                    Spacer()
                    Text("Your City")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("\(String(format: "%.0f", viewModel.cityWasteKg)) kg")
                            .font(.title2.bold())
                        Text("waste collected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("\(viewModel.cityVolunteers)")
                            .font(.title2.bold())
                        Text("active volunteers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal)

            // Active milestones
            VStack(alignment: .leading, spacing: 12) {
                Text("Active Challenges")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(viewModel.communityMilestones.filter { !$0.isCompleted }) { milestone in
                    CommunityMilestoneCard(milestone: milestone)
                }

                // Completed milestones
                Text("Completed")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ForEach(viewModel.communityMilestones.filter { $0.isCompleted }) { milestone in
                    CommunityMilestoneCard(milestone: milestone)
                }
            }
        }
    }

    // MARK: - Journey Timeline View

    private var journeyTimelineView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Cleanup Journey")
                .font(.headline)
                .padding(.horizontal)

            Text("Started \(viewModel.journeyItems.last?.date.formatted(date: .abbreviated, time: .omitted) ?? "recently")")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Timeline
            ForEach(Array(viewModel.journeyItems.reversed().enumerated()), id: \.element.id) { index, item in
                JourneyTimelineItem(item: item, isFirst: index == 0, isLast: index == viewModel.journeyItems.count - 1)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Live Map View

    private var liveMapView: some View {
        VStack(spacing: 16) {
            // Live indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("Live cleanups happening now")
                    .font(.subheadline)
                Spacer()
                Text("\(viewModel.recentCleanups.count) active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Map
            Map {
                ForEach(viewModel.recentCleanups) { activity in
                    Annotation(activity.userName, coordinate: activity.coordinate) {
                        LiveActivityMarker(activity: activity)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 300)
            .cornerRadius(16)
            .padding(.horizontal)

            // Recent activity list
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(viewModel.recentCleanups) { activity in
                    LiveActivityRow(activity: activity)
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Supporting Views

struct EquivalentCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
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
        .frame(width: 100)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

struct StatBubble: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct PersonalMilestoneRow: View {
    let milestone: PersonalMilestone

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(milestone.isCompleted ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: milestone.icon)
                        .foregroundColor(milestone.isCompleted ? .white : .gray)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(!milestone.isCompleted ? false : false)

                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if milestone.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Text("+\(milestone.points)")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(milestone.isCompleted ? 1 : 0.7)
    }
}

struct CommunityMilestoneCard: View {
    let milestone: CommunityMilestone

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(milestone.title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if milestone.isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                } else {
                    Text(milestone.deadline.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(milestone.description)
                .font(.caption)
                .foregroundColor(.secondary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(milestone.isCompleted ? Color.green : Color.orange)
                        .frame(width: geo.size.width * milestone.progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(String(format: "%.0f", milestone.currentKg)) / \(String(format: "%.0f", milestone.targetKg)) kg")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(milestone.participantCount)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            // Reward
            HStack(spacing: 4) {
                Image(systemName: "gift.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
                Text(milestone.reward)
                    .font(.caption)
                    .foregroundColor(.purple)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct JourneyTimelineItem: View {
    let item: JourneyItem
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline line and dot
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 2, height: 20)
                }

                Circle()
                    .fill(iconColor)
                    .frame(width: 12, height: 12)

                if !isLast {
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 20)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(item.title)
                    .font(.subheadline.weight(.semibold))

                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if item.wasteKg > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.caption2)
                        Text("\(String(format: "%.1f", item.wasteKg)) kg")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }

                if let location = item.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 16)

            Spacer()
        }
    }

    private var iconColor: Color {
        switch item.type {
        case .firstCleanup: return .green
        case .cleanup: return .blue
        case .event: return .purple
        case .milestone: return .orange
        case .tip: return .yellow
        case .streak: return .red
        }
    }
}

struct LiveActivityMarker: View {
    let activity: LiveCleanupActivity

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 30, height: 30)

                Image(systemName: "leaf.fill")
                    .font(.caption)
                    .foregroundColor(.white)
            }

            // Arrow
            ImpactTriangle()
                .fill(Color.green)
                .frame(width: 10, height: 6)
                .offset(y: -2)
        }
    }
}

struct ImpactTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct LiveActivityRow: View {
    let activity: LiveCleanupActivity

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.userName)
                    .font(.subheadline.weight(.medium))
                Text(activity.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", activity.wasteKg)) kg")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.green)
                Text(activity.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    ImpactDashboardView()
}
