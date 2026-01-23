// SkeletonView.swift
// Skeleton loading states for better UX

import SwiftUI

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.5),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Shapes

struct SkeletonBox: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - Post Card Skeleton

struct PostCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                SkeletonCircle(size: 44)
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonBox(width: 120, height: 16)
                    SkeletonBox(width: 80, height: 12)
                }
                Spacer()
            }

            // Description
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBox(height: 14)
                SkeletonBox(width: 250, height: 14)
            }

            // Image placeholder
            SkeletonBox(height: 200, cornerRadius: 12)

            // Stats row
            HStack(spacing: 24) {
                SkeletonBox(width: 60, height: 16)
                SkeletonBox(width: 60, height: 16)
                SkeletonBox(width: 60, height: 16)
            }

            // Action buttons
            HStack(spacing: 16) {
                SkeletonBox(width: 80, height: 32, cornerRadius: 16)
                SkeletonBox(width: 80, height: 32, cornerRadius: 16)
                Spacer()
                SkeletonBox(width: 80, height: 32, cornerRadius: 16)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Event Card Skeleton

struct EventCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cover image
            SkeletonBox(height: 150, cornerRadius: 12)

            // Title and date
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBox(width: 200, height: 18)
                SkeletonBox(width: 150, height: 14)
            }

            // Location
            HStack(spacing: 8) {
                SkeletonCircle(size: 20)
                SkeletonBox(width: 180, height: 14)
            }

            // Attendees and button
            HStack {
                SkeletonBox(width: 100, height: 14)
                Spacer()
                SkeletonBox(width: 80, height: 36, cornerRadius: 18)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Leaderboard Row Skeleton

struct LeaderboardRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonBox(width: 30, height: 20)
            SkeletonCircle(size: 44)
            VStack(alignment: .leading, spacing: 4) {
                SkeletonBox(width: 120, height: 16)
                SkeletonBox(width: 80, height: 12)
            }
            Spacer()
            SkeletonBox(width: 60, height: 20)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Profile Header Skeleton

struct ProfileHeaderSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            SkeletonCircle(size: 100)
            SkeletonBox(width: 150, height: 24)
            SkeletonBox(width: 200, height: 14)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    SkeletonBox(width: 40, height: 20)
                    SkeletonBox(width: 50, height: 12)
                }
                VStack(spacing: 4) {
                    SkeletonBox(width: 40, height: 20)
                    SkeletonBox(width: 50, height: 12)
                }
                VStack(spacing: 4) {
                    SkeletonBox(width: 40, height: 20)
                    SkeletonBox(width: 50, height: 12)
                }
            }
        }
    }
}

// MARK: - Loading State Modifier

struct SkeletonLoadingModifier<Skeleton: View>: ViewModifier {
    let isLoading: Bool
    let skeleton: () -> Skeleton

    func body(content: Content) -> some View {
        if isLoading {
            skeleton()
        } else {
            content
        }
    }
}

extension View {
    func skeleton<S: View>(
        isLoading: Bool,
        @ViewBuilder skeleton: @escaping () -> S
    ) -> some View {
        modifier(SkeletonLoadingModifier(isLoading: isLoading, skeleton: skeleton))
    }
}

// MARK: - Feed Loading View

struct FeedLoadingView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    PostCardSkeleton()
                }
            }
            .padding()
        }
    }
}

struct GatheringsLoadingView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    EventCardSkeleton()
                }
            }
            .padding()
        }
    }
}

struct LeaderboardLoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<10, id: \.self) { _ in
                LeaderboardRowSkeleton()
                Divider()
            }
        }
        .padding()
    }
}

#Preview {
    VStack(spacing: 20) {
        PostCardSkeleton()
        EventCardSkeleton()
    }
    .padding()
}
