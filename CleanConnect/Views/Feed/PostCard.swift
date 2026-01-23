// PostCard.swift
// Card component for displaying cleanup posts

import SwiftUI
import UIKit

struct PostCard: View {
    let post: Post
    @State private var showTipSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with user info
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: post.userPhotoURL ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(post.userName)
                            .font(.subheadline.weight(.semibold))
                        // Verification badge
                        VerificationBadgeView(badge: post.verificationBadge)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text("\(post.district), \(post.state)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(post.createdAt.timeAgo())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    // Video proof indicator
                    if post.hasVideoProof {
                        HStack(spacing: 2) {
                            Image(systemName: "video.fill")
                                .font(.caption2)
                            Text("Video")
                                .font(.caption2)
                        }
                        .foregroundColor(.green)
                    }
                }
            }

            // Before/After images
            TabView {
                if let beforeURL = post.beforeImageURL {
                    ImageWithLabel(url: beforeURL, label: "Before")
                }
                if let afterURL = post.afterImageURL {
                    ImageWithLabel(url: afterURL, label: "After")
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 250)
            .cornerRadius(12)

            // Description
            if !post.description.isEmpty {
                Text(post.description)
                    .font(.subheadline)
                    .lineLimit(3)
            }

            // Stats row
            HStack(spacing: 16) {
                // Waste collected
                Label {
                    Text("\(String(format: "%.1f", post.wasteCollectedKg)) kg")
                        .font(.caption.weight(.medium))
                } icon: {
                    Image(systemName: "trash.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                // Duration
                if let duration = post.durationMinutes {
                    Label {
                        Text("\(duration) min")
                            .font(.caption.weight(.medium))
                    } icon: {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                // Points earned
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("+\(post.pointsEarned) pts")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.green)
                }
            }

            // Video proof link
            if post.hasVideoProof, let videoURL = post.videoProofURL {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.ccIndiaGreen)
                    Text("Watch video proof")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.ccIndiaGreen)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.ccIndiaGreen)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.ccIndiaGreen.opacity(0.1))
                .cornerRadius(8)
                .onTapGesture {
                    if let url = URL(string: videoURL) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            // Community verification votes
            if post.communityVotes > 0 || post.communityDownvotes > 0 {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("\(post.communityVotes)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("\(post.communityDownvotes)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Text("Community votes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            // Engagement row
            HStack(spacing: 16) {
                EngagementButton(
                    icon: "heart",
                    filledIcon: "heart.fill",
                    count: post.likes,
                    isActive: post.isLiked,
                    activeColor: .red
                ) {
                    // Like action
                }

                EngagementButton(
                    icon: "bubble.left",
                    filledIcon: "bubble.left.fill",
                    count: post.comments,
                    isActive: false,
                    activeColor: .blue
                ) {
                    // Comment action
                }

                Spacer()

                // Prominent Tip Button
                Button(action: { showTipSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.subheadline)
                        if post.tipsReceived > 0 {
                            Text("₹\(post.tipsReceived)")
                                .font(.caption.weight(.bold))
                        } else {
                            Text("Send Tip")
                                .font(.caption.weight(.bold))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.ccTipGold)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }

                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showTipSheet) {
            TipSheet(post: post)
        }
    }
}

struct ImageWithLabel: View {
    let url: String
    let label: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            AsyncImage(url: URL(string: url)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                    )
            }
            .frame(maxWidth: .infinity)
            .clipped()

            Text(label)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(6)
                .padding(8)
        }
    }
}

struct EngagementButton: View {
    let icon: String
    let filledIcon: String
    let count: Int
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isActive ? filledIcon : icon)
                    .font(.subheadline)
                    .foregroundColor(isActive ? activeColor : .secondary)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct VerificationBadgeView: View {
    let badge: VerificationBadge

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: badge.icon)
                .font(.caption2)
        }
        .foregroundColor(badgeColor)
    }

    private var badgeColor: Color {
        switch badge {
        case .verified: return .blue
        case .videoProof: return .green
        case .communityVerified: return .orange
        case .unverified: return .gray
        }
    }
}

#Preview {
    PostCard(post: Post.preview)
        .padding()
}
