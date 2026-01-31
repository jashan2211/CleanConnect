// PostCard.swift
// Reddit-style engaging card for cleanup posts with map integration

import SwiftUI
import UIKit
import MapKit

struct PostCard: View {
    let post: Post
    @State private var showTipSheet = false
    @State private var showVideoPlayer = false
    @State private var showFullMap = false
    @State private var isUpvoted = false
    @State private var isDownvoted = false
    @State private var voteCount: Int

    init(post: Post) {
        self.post = post
        _voteCount = State(initialValue: post.communityVotes - post.communityDownvotes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top bar - Compact header with key stats
            topBar

            // Main content area
            mainContent

            // Engagement bar - Reddit style
            engagementBar
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showTipSheet) {
            TipSheet(post: post)
        }
        .sheet(isPresented: $showVideoPlayer) {
            if let videoURL = post.videoProofURL {
                VideoPlayerSheet(videoURL: videoURL)
            }
        }
        .sheet(isPresented: $showFullMap) {
            FullMapView(post: post)
        }
    }

    // MARK: - Top Bar (Compact Header)
    private var topBar: some View {
        HStack(spacing: 10) {
            // User avatar
            AsyncImage(url: URL(string: post.userPhotoURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .overlay(
                        Text(String(post.userName.prefix(1)).uppercased())
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    )
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            // User info & location
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(post.userName)
                        .font(.subheadline.weight(.semibold))
                    VerificationBadgeView(badge: post.verificationBadge)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("\(post.district)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(post.createdAt.timeAgo())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Impact badge - Eye-catching!
            impactBadge
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Impact Badge (Clickbaity stats)
    private var impactBadge: some View {
        VStack(spacing: 2) {
            Text("\(String(format: "%.1f", post.wasteCollectedKg))")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text("KG")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: impactGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(8)
    }

    private var impactGradientColors: [Color] {
        if post.wasteCollectedKg >= 10 {
            return [.purple, .pink] // Legendary
        } else if post.wasteCollectedKg >= 5 {
            return [.orange, .red] // Epic
        } else if post.wasteCollectedKg >= 2 {
            return [.green, .teal] // Good
        } else {
            return [.blue, .cyan] // Standard
        }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Description (if any)
            if !post.description.isEmpty {
                Text(post.description)
                    .font(.subheadline)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
            }

            // Media Section - Before/After or Video
            if post.hasVideoProof {
                videoPreview
            } else if post.beforeImageURL != nil || post.afterImageURL != nil {
                imageCarousel
            }

            // Mini Map Preview
            if post.latitude != nil && post.longitude != nil {
                miniMapPreview
            }

            // Quick Stats Row
            quickStatsRow
        }
    }

    // MARK: - Video Preview
    private var videoPreview: some View {
        ZStack(alignment: .bottomLeading) {
            if let videoURL = post.videoProofURL, videoURL.isYouTubeURL {
                YouTubeThumbnailView(videoURL: videoURL) {
                    showVideoPlayer = true
                }
                .frame(height: 200)
                .cornerRadius(0)
            } else {
                // Non-YouTube video placeholder
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            Text("Watch Video Proof")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    )
                    .onTapGesture {
                        if let urlString = post.videoProofURL,
                           let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    }
            }

            // Verified badge overlay
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                Text("VERIFIED")
                    .font(.caption2.bold())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green)
            .cornerRadius(4)
            .padding(8)
        }
    }

    // MARK: - Image Carousel
    private var imageCarousel: some View {
        TabView {
            if let beforeURL = post.beforeImageURL {
                ImageWithLabel(url: beforeURL, label: "BEFORE")
            }
            if let afterURL = post.afterImageURL {
                ImageWithLabel(url: afterURL, label: "AFTER")
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 200)
    }

    // MARK: - Mini Map Preview
    private var miniMapPreview: some View {
        Button(action: { showFullMap = true }) {
            ZStack(alignment: .bottomTrailing) {
                MapSnapshotView(
                    latitude: post.latitude ?? 0,
                    longitude: post.longitude ?? 0
                )
                .frame(height: 100)
                .cornerRadius(0)

                // Tap to expand hint
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption2)
                    Text("View Map")
                        .font(.caption2.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
                .padding(8)

                // Location pin in center
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                            .shadow(radius: 2)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Stats Row
    private var quickStatsRow: some View {
        HStack(spacing: 16) {
            // Duration
            if let duration = post.durationMinutes {
                PostStatPill(icon: "clock.fill", value: "\(duration)m", color: .blue)
            }

            // Points
            PostStatPill(icon: "star.fill", value: "+\(post.pointsEarned)", color: .yellow)

            // Tips (if any)
            if post.tipsReceived > 0 {
                PostStatPill(icon: "indianrupeesign.circle.fill", value: "₹\(post.tipsReceived)", color: .green)
            }

            Spacer()

            // Job proof badge
            if post.postType == .jobProof {
                HStack(spacing: 4) {
                    Image(systemName: "briefcase.fill")
                        .font(.caption2)
                    Text("Job Done")
                        .font(.caption2.bold())
                }
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Engagement Bar (Reddit Style)
    private var engagementBar: some View {
        HStack(spacing: 0) {
            // Upvote/Downvote cluster
            HStack(spacing: 0) {
                // Upvote
                Button(action: upvote) {
                    Image(systemName: isUpvoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .font(.title3)
                        .foregroundColor(isUpvoted ? .orange : .secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)

                // Vote count
                Text("\(voteCount)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(voteCount > 0 ? .orange : (voteCount < 0 ? .blue : .secondary))
                    .frame(minWidth: 30)

                // Downvote
                Button(action: downvote) {
                    Image(systemName: isDownvoted ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .font(.title3)
                        .foregroundColor(isDownvoted ? .blue : .secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
            .background(Color(.systemGray6))
            .cornerRadius(20)

            Spacer()

            // Comments
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.subheadline)
                    Text("\(post.comments)")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            // Share
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }

            // Tip button - Prominent!
            Button(action: { showTipSheet = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.subheadline)
                    Text("Tip")
                        .font(.caption.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.5))
    }

    // MARK: - Actions
    private func upvote() {
        let wasUpvoted = isUpvoted
        let wasDownvoted = isDownvoted

        // Optimistic UI update
        if isUpvoted {
            isUpvoted = false
            voteCount -= 1
        } else {
            if isDownvoted {
                isDownvoted = false
                voteCount += 1
            }
            isUpvoted = true
            voteCount += 1
        }

        // Sync with backend
        Task {
            do {
                let voteType = wasUpvoted ? "none" : "up"
                let result = try await PostService.shared.voteOnPost(postId: post.id, voteType: voteType)
                await MainActor.run {
                    voteCount = result.voteScore
                }
            } catch {
                // Revert on error
                await MainActor.run {
                    isUpvoted = wasUpvoted
                    isDownvoted = wasDownvoted
                    voteCount = post.communityVotes - post.communityDownvotes
                }
            }
        }
    }

    private func downvote() {
        let wasUpvoted = isUpvoted
        let wasDownvoted = isDownvoted

        // Optimistic UI update
        if isDownvoted {
            isDownvoted = false
            voteCount += 1
        } else {
            if isUpvoted {
                isUpvoted = false
                voteCount -= 1
            }
            isDownvoted = true
            voteCount -= 1
        }

        // Sync with backend
        Task {
            do {
                let voteType = wasDownvoted ? "none" : "down"
                let result = try await PostService.shared.voteOnPost(postId: post.id, voteType: voteType)
                await MainActor.run {
                    voteCount = result.voteScore
                }
            } catch {
                // Revert on error
                await MainActor.run {
                    isUpvoted = wasUpvoted
                    isDownvoted = wasDownvoted
                    voteCount = post.communityVotes - post.communityDownvotes
                }
            }
        }
    }
}

// MARK: - Post Stat Pill Component
struct PostStatPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(value)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Map Snapshot View (In-app preview)
struct MapSnapshotView: View {
    let latitude: Double
    let longitude: Double
    @State private var snapshot: UIImage?

    var body: some View {
        Group {
            if let snapshot = snapshot {
                Image(uiImage: snapshot)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        ProgressView()
                    )
            }
        }
        .onAppear {
            generateSnapshot()
        }
    }

    private func generateSnapshot() {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )

        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 400, height: 200)
        options.scale = UIScreen.main.scale

        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { result, error in
            guard let result = result, error == nil else { return }

            // Add a pin to the snapshot
            let image = result.image
            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
            image.draw(at: .zero)

            // Draw pin
            let point = result.point(for: coordinate)
            let pinImage = UIImage(systemName: "mappin.circle.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
            pinImage?.draw(at: CGPoint(x: point.x - 15, y: point.y - 30), blendMode: .normal, alpha: 1.0)

            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            DispatchQueue.main.async {
                self.snapshot = finalImage
            }
        }
    }
}

// MARK: - Full Map View
struct FullMapView: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion

    init(post: Post) {
        self.post = post
        let coordinate = CLLocationCoordinate2D(
            latitude: post.latitude ?? 0,
            longitude: post.longitude ?? 0
        )
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: [post]) { post in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: post.latitude ?? 0,
                        longitude: post.longitude ?? 0
                    )) {
                        VStack(spacing: 0) {
                            Image(systemName: "leaf.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                                .background(Circle().fill(.white).frame(width: 30, height: 30))

                            Image(systemName: "triangle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .rotationEffect(.degrees(180))
                                .offset(y: -3)
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                // Info card at bottom
                VStack {
                    Spacer()
                    mapInfoCard
                }
            }
            .navigationTitle("Cleanup Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: openInMaps) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond")
                            Text("Directions")
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }

    private var mapInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AsyncImage(url: URL(string: post.userPhotoURL ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.green.opacity(0.2))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.subheadline.bold())
                    Text("\(post.district), \(post.state)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("\(String(format: "%.1f", post.wasteCollectedKg)) kg")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("cleaned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let address = post.address {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding()
    }

    private func openInMaps() {
        guard let lat = post.latitude, let lon = post.longitude else { return }
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Cleanup Location"
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Supporting Views (Keep existing ones)

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
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(label == "BEFORE" ? Color.red : Color.green)
                .cornerRadius(4)
                .padding(8)
        }
    }
}

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
        .onAppear { loadImage() }
    }

    private func loadImage() {
        if urlString.hasPrefix("/") {
            let fileURL = URL(fileURLWithPath: urlString)
            if let data = try? Data(contentsOf: fileURL),
               let image = UIImage(data: data) {
                self.uiImage = image
            }
            isLoading = false
        } else if let url = URL(string: urlString) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            self.uiImage = image
                            self.isLoading = false
                        }
                    } else {
                        await MainActor.run { self.isLoading = false }
                    }
                } catch {
                    await MainActor.run { self.isLoading = false }
                }
            }
        } else {
            isLoading = false
        }
    }
}

struct VerificationBadgeView: View {
    let badge: VerificationBadge

    var body: some View {
        Image(systemName: badge.icon)
            .font(.caption2)
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

// MARK: - YouTube Components

extension String {
    var isYouTubeURL: Bool {
        let patterns = ["youtube\\.com\\/watch", "youtu\\.be\\/", "youtube\\.com\\/embed", "youtube\\.com\\/shorts"]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: self, range: NSRange(self.startIndex..., in: self)) != nil {
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
               let match = regex.firstMatch(in: self, range: NSRange(self.startIndex..., in: self)),
               let range = Range(match.range(at: 1), in: self) {
                return String(self[range])
            }
        }
        return nil
    }
}

struct VideoPlayerSheet: View {
    let videoURL: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // YouTube thumbnail
                if let thumbnailURL = thumbnailURL {
                    AsyncImage(url: thumbnailURL) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(12)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.black)
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(12)
                            .overlay(ProgressView().tint(.white))
                    }
                    .padding(.horizontal)
                }

                // Open in YouTube button
                Button {
                    openInYouTube()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.title2)
                        Text("Watch on YouTube")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Text("Videos open in the YouTube app for the best viewing experience")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Video Proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var thumbnailURL: URL? {
        guard let id = videoURL.youTubeVideoId else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")
    }

    private func openInYouTube() {
        guard let videoId = videoURL.youTubeVideoId else { return }

        // Try YouTube app first, then Safari
        let youtubeAppURL = URL(string: "youtube://\(videoId)")
        let youtubeWebURL = URL(string: "https://www.youtube.com/watch?v=\(videoId)")

        if let appURL = youtubeAppURL, UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = youtubeWebURL {
            UIApplication.shared.open(webURL)
        }
    }
}

import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoURL: String
    var autoplay: Bool = false

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = autoplay ? [] : [.all]
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.hasLoaded { return }
        context.coordinator.hasLoaded = true
        guard let videoId = videoURL.youTubeVideoId else { return }
        let embedURL = "https://www.youtube-nocookie.com/embed/\(videoId)?playsinline=1&rel=0&modestbranding=1\(autoplay ? "&autoplay=1" : "")"
        if let url = URL(string: embedURL) {
            webView.load(URLRequest(url: url))
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var hasLoaded = false
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

struct YouTubeThumbnailView: View {
    let videoURL: String
    var onTap: (() -> Void)?

    private var thumbnailURL: URL? {
        guard let id = videoURL.youTubeVideoId else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")
    }

    var body: some View {
        ZStack {
            if let url = thumbnailURL {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.black).overlay(ProgressView().tint(.white))
                }
            } else {
                Rectangle().fill(Color.black)
            }

            // Play button
            Button(action: { onTap?() ?? openYouTube() }) {
                ZStack {
                    Circle().fill(Color.red).frame(width: 60, height: 60)
                    Image(systemName: "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .offset(x: 2)
                }
            }

            // YouTube badge
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "play.rectangle.fill")
                        Text("YouTube")
                    }
                    .font(.caption2.weight(.medium))
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

    private func openYouTube() {
        guard let id = videoURL.youTubeVideoId,
              let url = URL(string: "https://www.youtube.com/watch?v=\(id)") else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ScrollView {
        PostCard(post: Post.preview)
            .padding()
    }
}
