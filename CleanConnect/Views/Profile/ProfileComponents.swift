// ProfileComponents.swift
// Reusable components for Profile views

import SwiftUI

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct BadgeView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 4) {
            Text(badge.emoji)
                .font(.largeTitle)
            Text(badge.name)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 70)
    }
}

struct ActivityRow: View {
    let activity: UserActivity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(activity.color)
                .frame(width: 36, height: 36)
                .background(activity.color.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                Text(activity.timestamp.timeAgo())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let points = activity.pointsEarned {
                Text("+\(points) pts")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
    }
}

struct MenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct AllBadgesView: View {
    var body: some View {
        Text("All Badges")
            .navigationTitle("Badges")
    }
}
