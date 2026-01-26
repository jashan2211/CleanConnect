// LiveStreamView.swift
// YouTube Live Stream embed for ongoing events - iOS 17+

import SwiftUI
import WebKit

// MARK: - Live Stream Card (Preview in Event Detail)

struct LiveStreamCard: View {
    let streamURL: String
    let eventTitle: String
    let viewerCount: Int
    @Binding var showFullScreen: Bool

    @State private var isLive = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Live indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .fill(Color.red.opacity(0.5))
                                .frame(width: 16, height: 16)
                                .scaleEffect(isLive ? 1.5 : 1.0)
                                .opacity(isLive ? 0 : 1)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isLive)
                        )

                    Text("LIVE")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.red)
                }

                Spacer()

                // Viewer count
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.caption2)
                    Text("\(viewerCount) watching")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            // Stream thumbnail with play overlay
            Button {
                showFullScreen = true
            } label: {
                ZStack {
                    // Thumbnail
                    if let videoId = extractYouTubeId(from: streamURL) {
                        AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.red.opacity(0.3), .orange.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    // Dark overlay
                    Color.black.opacity(0.3)

                    // Play button
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 60, height: 60)

                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .offset(x: 2)
                        }

                        Text("Watch Live Stream")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }

                    // Live badge
                    VStack {
                        HStack {
                            Spacer()
                            Text("LIVE")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red)
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .frame(height: 180)
            .cornerRadius(12)
            .clipped()
            .buttonStyle(.plain)

            // Event title
            Text(eventTitle)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .red.opacity(0.2), radius: 8, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            isLive = true
        }
    }

    private func extractYouTubeId(from url: String) -> String? {
        let patterns = [
            "(?:youtube\\.com\\/watch\\?v=)([a-zA-Z0-9_-]{11})",
            "(?:youtu\\.be\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/embed\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/live\\/)([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: url, options: [], range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                return String(url[range])
            }
        }
        return nil
    }
}

// MARK: - Full Screen Live Stream View

struct LiveStreamFullScreenView: View {
    let streamURL: String
    let eventTitle: String
    @Environment(\.dismiss) private var dismiss

    @State private var showControls = true
    @State private var viewerCount = 0
    @State private var chatMessages: [LiveChatMessage] = []
    @State private var newMessage = ""
    @State private var showChat = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video player
                LiveStreamPlayer(streamURL: streamURL)
                    .ignoresSafeArea()

                // Controls overlay
                if showControls {
                    VStack {
                        // Top bar
                        topBar
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.black.opacity(0.7), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Spacer()

                        // Bottom controls & chat
                        if showChat {
                            chatOverlay
                                .frame(height: geometry.size.height * 0.4)
                        }

                        // Bottom bar
                        bottomBar
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls.toggle()
                }
            }
        }
        .statusBarHidden(!showControls)
        .onAppear {
            loadMockChat()
            viewerCount = Int.random(in: 50...500)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(eventTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Live badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(4)

                    // Viewers
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                        Text("\(viewerCount)")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()

            // Share button
            Button {
                // Share stream
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
        }
    }

    private var chatOverlay: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(chatMessages) { message in
                        LiveChatBubble(message: message)
                    }
                }
                .padding(.horizontal)
            }
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            // Chat toggle
            Button {
                withAnimation { showChat.toggle() }
            } label: {
                Image(systemName: showChat ? "bubble.left.fill" : "bubble.left")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            // Chat input
            HStack {
                TextField("Say something...", text: $newMessage)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .tint(.white)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(newMessage.isEmpty ? .gray : .white)
                }
                .disabled(newMessage.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)

            // Reactions
            Button {
                // Send reaction
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundColor(.red)
            }
        }
    }

    private func sendMessage() {
        guard !newMessage.isEmpty else { return }

        let message = LiveChatMessage(
            id: UUID().uuidString,
            userName: UserState.shared.currentUser?.displayName ?? "You",
            message: newMessage,
            timestamp: Date(),
            isOrganizer: false
        )

        chatMessages.append(message)
        newMessage = ""
    }

    private func loadMockChat() {
        chatMessages = [
            LiveChatMessage(id: "1", userName: "Organizer", message: "Welcome everyone! We're starting the cleanup at Juhu Beach!", timestamp: Date().addingTimeInterval(-300), isOrganizer: true),
            LiveChatMessage(id: "2", userName: "Rahul", message: "Great turnout today! 💪", timestamp: Date().addingTimeInterval(-240), isOrganizer: false),
            LiveChatMessage(id: "3", userName: "Priya", message: "Where should I park?", timestamp: Date().addingTimeInterval(-180), isOrganizer: false),
            LiveChatMessage(id: "4", userName: "Organizer", message: "Parking available near the food court", timestamp: Date().addingTimeInterval(-150), isOrganizer: true),
            LiveChatMessage(id: "5", userName: "Amit", message: "On my way! 🏃", timestamp: Date().addingTimeInterval(-100), isOrganizer: false),
            LiveChatMessage(id: "6", userName: "Sneha", message: "This is amazing! So much plastic collected already", timestamp: Date().addingTimeInterval(-60), isOrganizer: false),
        ]
    }
}

// MARK: - Live Chat Message

struct LiveChatMessage: Identifiable {
    let id: String
    let userName: String
    let message: String
    let timestamp: Date
    let isOrganizer: Bool
}

struct LiveChatBubble: View {
    let message: LiveChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            Circle()
                .fill(message.isOrganizer ? Color.blue : Color.gray.opacity(0.5))
                .frame(width: 24, height: 24)
                .overlay(
                    Text(String(message.userName.prefix(1)))
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(message.userName)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(message.isOrganizer ? .blue : .white)

                    if message.isOrganizer {
                        Text("Organizer")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }

                Text(message.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Live Stream Player (WKWebView)

struct LiveStreamPlayer: UIViewRepresentable {
    let streamURL: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsPictureInPictureMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let videoId = extractYouTubeId() else { return }

        // YouTube live embed with chat disabled, autoplay enabled
        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; }
                html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
                iframe { width: 100%; height: 100%; border: 0; }
            </style>
        </head>
        <body>
            <iframe
                src="https://www.youtube.com/embed/\(videoId)?autoplay=1&playsinline=1&rel=0&modestbranding=1&controls=1&showinfo=0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen>
            </iframe>
        </body>
        </html>
        """

        webView.loadHTMLString(embedHTML, baseURL: nil)
    }

    private func extractYouTubeId() -> String? {
        let patterns = [
            "(?:youtube\\.com\\/watch\\?v=)([a-zA-Z0-9_-]{11})",
            "(?:youtu\\.be\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/embed\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/live\\/)([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: streamURL, options: [], range: NSRange(streamURL.startIndex..., in: streamURL)),
               let range = Range(match.range(at: 1), in: streamURL) {
                return String(streamURL[range])
            }
        }
        return nil
    }
}

// MARK: - Ongoing Events List with Live Streams

struct OngoingEventsView: View {
    @State private var ongoingEvents: [Gathering] = []
    @State private var isLoading = false
    @State private var selectedEvent: Gathering?
    @State private var showLiveStream = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Finding live events...")
                } else if ongoingEvents.isEmpty {
                    emptyState
                } else {
                    eventsList
                }
            }
            .navigationTitle("Live Now")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showLiveStream) {
                if let event = selectedEvent, let streamURL = event.liveStreamURL {
                    LiveStreamFullScreenView(streamURL: streamURL, eventTitle: event.title)
                }
            }
            .task {
                await loadOngoingEvents()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Live Events")
                .font(.headline)

            Text("Check back later for live cleanup streams")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var eventsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(ongoingEvents) { event in
                    if let streamURL = event.liveStreamURL {
                        LiveStreamCard(
                            streamURL: streamURL,
                            eventTitle: event.title,
                            viewerCount: Int.random(in: 20...300),
                            showFullScreen: Binding(
                                get: { selectedEvent?.id == event.id && showLiveStream },
                                set: { newValue in
                                    if newValue {
                                        selectedEvent = event
                                        showLiveStream = true
                                    }
                                }
                            )
                        )
                        .onTapGesture {
                            selectedEvent = event
                            showLiveStream = true
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func loadOngoingEvents() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Mock ongoing events with live streams
        ongoingEvents = [
            Gathering(
                id: "live-1",
                organizerId: "org-1",
                organizerName: "Mumbai Beach Warriors",
                organizerPhotoURL: nil,
                title: "Juhu Beach Morning Cleanup",
                description: "Join our weekly beach cleanup!",
                imageURL: nil,
                eventDate: Date(),
                endDate: Date().addingTimeInterval(3600 * 2),
                durationHours: 2,
                state: "Maharashtra",
                district: "Mumbai",
                address: "Juhu Beach, Near Food Court",
                latitude: 19.0883,
                longitude: 72.8264,
                attendeesCount: 45,
                maxAttendees: 100,
                fundraisingGoal: nil,
                fundraisingRaised: nil,
                whatsappGroupLink: nil,
                videoMessageURL: nil,
                liveStreamURL: "https://www.youtube.com/watch?v=jfKfPfyJRdk",  // Mock live stream
                status: "ongoing",
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: nil
            ),
            Gathering(
                id: "live-2",
                organizerId: "org-2",
                organizerName: "Green Delhi Initiative",
                organizerPhotoURL: nil,
                title: "Yamuna Ghat Cleanup Drive",
                description: "Restoring the holy river banks",
                imageURL: nil,
                eventDate: Date(),
                endDate: Date().addingTimeInterval(3600 * 3),
                durationHours: 3,
                state: "Delhi",
                district: "Central Delhi",
                address: "Yamuna Ghat, Near ISBT",
                latitude: 28.6692,
                longitude: 77.2311,
                attendeesCount: 78,
                maxAttendees: 150,
                fundraisingGoal: nil,
                fundraisingRaised: nil,
                whatsappGroupLink: nil,
                videoMessageURL: nil,
                liveStreamURL: "https://www.youtube.com/watch?v=DWcJFNfaw9c",  // Mock live stream
                status: "ongoing",
                createdAt: Date().addingTimeInterval(-86400 * 2),
                updatedAt: nil
            ),
        ]

        isLoading = false
    }
}

#Preview {
    OngoingEventsView()
}
