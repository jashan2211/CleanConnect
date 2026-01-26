// PostCard.swift
// Card component for displaying cleanup posts

import SwiftUI
import UIKit

struct PostCard: View {
    let post: Post
    @State private var showTipSheet = false
    @State private var showVideoPlayer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Job proof badge (if this is a job completion post)
            if post.postType == .jobProof, let jobTitle = post.jobTitle {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Job Completed")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.green)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(jobTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }

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

            // Video proof - YouTube embed or external link
            if post.hasVideoProof, let videoURL = post.videoProofURL {
                if videoURL.isYouTubeURL {
                    // YouTube video - show thumbnail with inline player
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Video Proof")
                                .font(.caption.weight(.semibold))
                            Spacer()
                            Text("YouTube")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        YouTubeThumbnailView(videoURL: videoURL) {
                            showVideoPlayer = true
                        }
                        .frame(height: 160)
                        .cornerRadius(10)
                        .clipped()
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(12)
                } else {
                    // Non-YouTube video - show link
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
        .sheet(isPresented: $showVideoPlayer) {
            if let videoURL = post.videoProofURL {
                VideoPlayerSheet(videoURL: videoURL)
            }
        }
    }
}

struct ImageWithLabel: View {
    let url: String
    let label: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            LocalOrRemoteImage(urlString: url)
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

// MARK: - Local or Remote Image Loader

struct LocalOrRemoteImage: View {
    let urlString: String
    @State private var uiImage: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(ProgressView())
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        // Check if it's a local file path
        if urlString.hasPrefix("/") {
            // Local file path
            let fileURL = URL(fileURLWithPath: urlString)
            if let data = try? Data(contentsOf: fileURL),
               let image = UIImage(data: data) {
                self.uiImage = image
            }
            isLoading = false
        } else if let url = URL(string: urlString) {
            // Remote URL
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            self.uiImage = image
                            self.isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            self.isLoading = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            }
        } else {
            isLoading = false
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

// MARK: - YouTube URL Detection

extension String {
    var isYouTubeURL: Bool {
        let patterns = [
            "youtube\\.com\\/watch",
            "youtu\\.be\\/",
            "youtube\\.com\\/embed",
            "youtube\\.com\\/shorts"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: self, options: [], range: NSRange(self.startIndex..., in: self)) != nil {
                return true
            }
        }
        return false
    }

    var youTubeVideoId: String? {
        let patterns = [
            "(?:youtube\\.com\\/watch\\?v=)([a-zA-Z0-9_-]{11})",
            "(?:youtu\\.be\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/embed\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/shorts\\/)([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: self, options: [], range: NSRange(self.startIndex..., in: self)),
               let range = Range(match.range(at: 1), in: self) {
                return String(self[range])
            }
        }
        return nil
    }
}

// MARK: - Video Player Sheet

struct VideoPlayerSheet: View {
    let videoURL: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            YouTubePlayerView(videoURL: videoURL, autoplay: true)
                .ignoresSafeArea()
                .navigationTitle("Video Proof")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - YouTube Player View (WKWebView wrapper)

import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoURL: String
    var autoplay: Bool = false

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = autoplay ? [] : [.all]

        // Allow YouTube to work properly
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(videoURL: videoURL)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Prevent reloading if already loaded
        if context.coordinator.hasLoaded { return }
        context.coordinator.hasLoaded = true

        guard let videoId = videoURL.youTubeVideoId else { return }

        // Use YouTube's nocookie domain for better privacy and fewer restrictions
        let embedURL = "https://www.youtube-nocookie.com/embed/\(videoId)?playsinline=1&rel=0&modestbranding=1&enablejsapi=1\(autoplay ? "&autoplay=1" : "")"

        if let url = URL(string: embedURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var hasLoaded = false
        let videoURL: String

        init(videoURL: String) {
            self.videoURL = videoURL
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("YouTube load failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow YouTube embeds to work
            if let url = navigationAction.request.url {
                let urlString = url.absoluteString
                if urlString.contains("youtube") || urlString.contains("googlevideo") {
                    decisionHandler(.allow)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - YouTube Thumbnail View

struct YouTubeThumbnailView: View {
    let videoURL: String
    var onTap: (() -> Void)? = nil

    private var videoId: String? {
        videoURL.youTubeVideoId
    }

    private var thumbnailURL: URL? {
        guard let id = videoId else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")
    }

    init(videoURL: String, onTap: (() -> Void)? = nil) {
        self.videoURL = videoURL
        self.onTap = onTap
    }

    var body: some View {
        ZStack {
            // Thumbnail
            if let url = thumbnailURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.black)
                        .aspectRatio(16/9, contentMode: .fill)
                        .overlay(ProgressView().tint(.white))
                }
            } else {
                Rectangle()
                    .fill(Color.black)
                    .aspectRatio(16/9, contentMode: .fill)
            }

            // Play button overlay
            Button(action: handleTap) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 60, height: 60)

                    Image(systemName: "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .offset(x: 2)
                }
            }

            // "Watch on YouTube" label
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.caption2)
                        Text("YouTube")
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(8)
                }
            }
        }
        .clipped()
    }

    private func handleTap() {
        if let onTap = onTap {
            onTap()
        } else {
            openInYouTube()
        }
    }

    private func openInYouTube() {
        guard let id = videoId else { return }

        // Try YouTube app first
        if let appURL = URL(string: "youtube://\(id)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: "https://www.youtube.com/watch?v=\(id)") {
            // Fall back to browser
            UIApplication.shared.open(webURL)
        }
    }
}

#Preview {
    PostCard(post: Post.preview)
        .padding()
}
