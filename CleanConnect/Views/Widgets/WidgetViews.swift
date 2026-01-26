// WidgetViews.swift
// Widget-ready views for Home Screen widgets
// These views are designed to work with WidgetKit
// To use: Add a Widget Extension target in Xcode and use these views

import SwiftUI

// MARK: - Widget Data Model

struct CleanupWidgetData: Codable {
    let totalWasteKg: Double
    let totalCleanups: Int
    let currentStreak: Int
    let todayGoalKg: Double
    let todayCollectedKg: Double
    let rank: Int
    let pointsToday: Int
    let nearbyJobs: Int
    let lastUpdated: Date

    static let placeholder = CleanupWidgetData(
        totalWasteKg: 127.5,
        totalCleanups: 34,
        currentStreak: 7,
        todayGoalKg: 5.0,
        todayCollectedKg: 2.3,
        rank: 156,
        pointsToday: 75,
        nearbyJobs: 12,
        lastUpdated: Date()
    )
}

// MARK: - Small Widget View (Circular/Square)

struct SmallWidgetView: View {
    let data: CleanupWidgetData

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.green.opacity(0.8), Color.green],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 4) {
                // Streak indicator
                if data.currentStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(data.currentStreak)")
                            .font(.caption2.bold())
                    }
                    .foregroundColor(.orange)
                }

                // Main stat
                Text("\(String(format: "%.1f", data.totalWasteKg))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("kg collected")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))

                // Today's progress
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 8))
                    Text("+\(String(format: "%.1f", data.todayCollectedKg)) today")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

// MARK: - Medium Widget View (Rectangular)

struct MediumWidgetView: View {
    let data: CleanupWidgetData

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)

            HStack(spacing: 16) {
                // Left: Main stats
                VStack(alignment: .leading, spacing: 8) {
                    // Streak
                    if data.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(data.currentStreak) day streak")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    // Total waste
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(String(format: "%.1f", data.totalWasteKg)) kg")
                            .font(.title.bold())
                            .foregroundColor(.green)
                        Text("total collected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Cleanups count
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("\(data.totalCleanups) cleanups")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Right: Today's progress
                VStack(spacing: 8) {
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 6)

                        Circle()
                            .trim(from: 0, to: min(data.todayCollectedKg / data.todayGoalKg, 1.0))
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("\(String(format: "%.1f", data.todayCollectedKg))")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Text("/ \(String(format: "%.0f", data.todayGoalKg))")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 70, height: 70)

                    Text("Today's Goal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let data: CleanupWidgetData

    var body: some View {
        ZStack {
            Color(.systemBackground)

            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                    Text("CleanConnect")
                        .font(.headline)
                    Spacer()

                    if data.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                            Text("\(data.currentStreak)")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }

                // Main stats row
                HStack(spacing: 20) {
                    WidgetStatItem(
                        value: "\(String(format: "%.1f", data.totalWasteKg))",
                        unit: "kg",
                        label: "Total Collected",
                        icon: "scalemass.fill",
                        color: .green
                    )

                    WidgetStatItem(
                        value: "\(data.totalCleanups)",
                        unit: "",
                        label: "Cleanups",
                        icon: "checkmark.circle.fill",
                        color: .blue
                    )

                    WidgetStatItem(
                        value: "#\(data.rank)",
                        unit: "",
                        label: "Rank",
                        icon: "trophy.fill",
                        color: .yellow
                    )
                }

                Divider()

                // Today's progress
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Progress")
                            .font(.subheadline.weight(.medium))

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)

                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: geo.size.width * min(data.todayCollectedKg / data.todayGoalKg, 1.0), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text("\(String(format: "%.1f", data.todayCollectedKg)) kg collected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Goal: \(String(format: "%.0f", data.todayGoalKg)) kg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Points today
                    VStack(spacing: 2) {
                        Text("+\(data.pointsToday)")
                            .font(.title3.bold())
                            .foregroundColor(.green)
                        Text("pts today")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Quick actions hint
                HStack {
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(.green)
                    Text("\(data.nearbyJobs) cleanup jobs nearby")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Tap to view")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
    }
}

struct WidgetStatItem: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            HStack(spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Lock Screen Widget (Circular)

struct LockScreenWidgetView: View {
    let data: CleanupWidgetData

    var body: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)

            Circle()
                .trim(from: 0, to: min(data.todayCollectedKg / data.todayGoalKg, 1.0))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Image(systemName: "leaf.fill")
                    .font(.caption)
                Text("\(String(format: "%.1f", data.todayCollectedKg))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
        }
    }
}

// MARK: - Widget Preview Container

struct WidgetPreviewContainer: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Widget Previews")
                        .font(.headline)

                    // Small widget
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Small Widget")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        SmallWidgetView(data: .placeholder)
                            .frame(width: 155, height: 155)
                            .cornerRadius(22)
                    }

                    // Medium widget
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medium Widget")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        MediumWidgetView(data: .placeholder)
                            .frame(width: 329, height: 155)
                            .cornerRadius(22)
                            .shadow(radius: 2)
                    }

                    // Large widget
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Large Widget")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        LargeWidgetView(data: .placeholder)
                            .frame(width: 329, height: 345)
                            .cornerRadius(22)
                            .shadow(radius: 2)
                    }

                    // Lock screen
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lock Screen Widget")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        LockScreenWidgetView(data: .placeholder)
                            .frame(width: 50, height: 50)
                    }

                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to Add Widgets")
                            .font(.headline)
                            .padding(.top)

                        Text("1. Long press on your Home Screen\n2. Tap the + button in top left\n3. Search for 'CleanConnect'\n4. Choose your widget size\n5. Tap 'Add Widget'")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Widgets")
        }
    }
}

#Preview {
    WidgetPreviewContainer()
}
