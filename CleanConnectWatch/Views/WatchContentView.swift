// WatchContentView.swift
// Main content view for Apple Watch companion app

import SwiftUI
import WatchKit

// MARK: - Watch Data Model

struct WatchCleanupData: Codable {
    var totalWasteKg: Double
    var totalCleanups: Int
    var currentStreak: Int
    var todayWasteKg: Double
    var todayGoalKg: Double
    var pointsToday: Int
    var rank: Int
    var lastUpdated: Date

    static let sample = WatchCleanupData(
        totalWasteKg: 127.5,
        totalCleanups: 34,
        currentStreak: 7,
        todayWasteKg: 2.3,
        todayGoalKg: 5.0,
        pointsToday: 75,
        rank: 156,
        lastUpdated: Date()
    )
}

// MARK: - Main Content View

struct WatchContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchHomeView()
                .tag(0)

            QuickLogView()
                .tag(1)

            WatchStatsView()
                .tag(2)
        }
        .tabViewStyle(.verticalPage)
    }
}

// MARK: - Home View

struct WatchHomeView: View {
    @State private var data = WatchCleanupData.sample

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Streak indicator
                if data.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(data.currentStreak) day streak")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                // Today's progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: min(data.todayWasteKg / data.todayGoalKg, 1.0))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(String(format: "%.1f", data.todayWasteKg))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        Text("kg today")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                // Goal progress text
                Text("Goal: \(String(format: "%.0f", data.todayGoalKg)) kg")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Quick stats
                HStack(spacing: 16) {
                    VStack {
                        Text("\(data.pointsToday)")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("points")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text("#\(data.rank)")
                            .font(.headline)
                            .foregroundColor(.yellow)
                        Text("rank")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("CleanConnect")
    }
}

// MARK: - Quick Log View

struct QuickLogView: View {
    @State private var wasteAmount: Double = 0.5
    @State private var isLogging = false
    @State private var showConfirmation = false

    let presetAmounts: [Double] = [0.5, 1.0, 2.0, 5.0]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Quick Log")
                    .font(.headline)

                // Amount display
                Text("\(String(format: "%.1f", wasteAmount)) kg")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.green)

                // Preset buttons
                HStack(spacing: 8) {
                    ForEach(presetAmounts, id: \.self) { amount in
                        Button {
                            wasteAmount = amount
                            WKInterfaceDevice.current().play(.click)
                        } label: {
                            Text("\(String(format: "%.1f", amount))")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(wasteAmount == amount ? Color.green : Color.gray.opacity(0.3))
                                .foregroundColor(wasteAmount == amount ? .black : .white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Manual adjustment
                HStack {
                    Button {
                        if wasteAmount > 0.1 {
                            wasteAmount -= 0.1
                            WKInterfaceDevice.current().play(.click)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        wasteAmount += 0.1
                        WKInterfaceDevice.current().play(.click)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                // Log button
                Button {
                    logCleanup()
                } label: {
                    HStack {
                        Image(systemName: "leaf.fill")
                        Text("Log Cleanup")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(isLogging)
            }
            .padding()
        }
        .alert("Logged!", isPresented: $showConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(String(format: "%.1f", wasteAmount)) kg cleanup logged successfully!")
        }
    }

    private func logCleanup() {
        isLogging = true
        WKInterfaceDevice.current().play(.success)

        // In real implementation, this would sync with the iOS app
        // via Watch Connectivity framework

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLogging = false
            showConfirmation = true
        }
    }
}

// MARK: - Stats View

struct WatchStatsView: View {
    @State private var data = WatchCleanupData.sample

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Your Impact")
                    .font(.headline)

                // Total waste collected
                VStack(spacing: 4) {
                    Text("\(String(format: "%.1f", data.totalWasteKg))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text("kg total collected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatBox(value: "\(data.totalCleanups)", label: "Cleanups", icon: "checkmark.circle.fill", color: .blue)
                    StatBox(value: "\(data.currentStreak)", label: "Day Streak", icon: "flame.fill", color: .orange)
                    StatBox(value: "#\(data.rank)", label: "Rank", icon: "trophy.fill", color: .yellow)
                    StatBox(value: "\(data.pointsToday)", label: "Today", icon: "star.fill", color: .green)
                }

                // Environmental impact
                VStack(spacing: 8) {
                    Text("You've saved")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        Text("\(Int(data.totalWasteKg * 5)) liters of water")
                            .font(.caption)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Stats")
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Complications View (for Watch Face)

struct ComplicationView: View {
    let data: WatchCleanupData

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)

            Circle()
                .trim(from: 0, to: min(data.todayWasteKg / data.todayGoalKg, 1.0))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
                Text("\(String(format: "%.1f", data.todayWasteKg))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
        }
    }
}

// MARK: - Rectangular Complication

struct RectangularComplicationView: View {
    let data: WatchCleanupData

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("CleanConnect")
                        .font(.caption2)
                }

                Text("\(String(format: "%.1f", data.todayWasteKg)) kg today")
                    .font(.caption)
                    .fontWeight(.medium)

                if data.currentStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                        Text("\(data.currentStreak) day streak")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: min(data.todayWasteKg / data.todayGoalKg, 1.0))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Corner Complication

struct CornerComplicationView: View {
    let data: WatchCleanupData

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
            Text("\(String(format: "%.0f", data.todayWasteKg))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
        }
    }
}

#Preview {
    WatchContentView()
}
