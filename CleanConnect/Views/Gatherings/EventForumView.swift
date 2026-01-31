// EventForumView.swift
// Reddit-style threaded discussion for events

import SwiftUI

struct EventForumView: View {
    let event: Gathering
    @StateObject private var viewModel: EventForumViewModel
    @State private var newComment = ""
    @State private var replyingTo: EventComment?
    @State private var sortOption: SortOption = .hot
    @FocusState private var isCommentFocused: Bool

    enum SortOption: String, CaseIterable {
        case hot = "Hot"
        case new = "New"
        case top = "Top"

        var icon: String {
            switch self {
            case .hot: return "flame.fill"
            case .new: return "clock.fill"
            case .top: return "arrow.up.circle.fill"
            }
        }
    }

    init(event: Gathering) {
        self.event = event
        _viewModel = StateObject(wrappedValue: EventForumViewModel(eventId: event.id))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sort options
            sortHeader

            Divider()

            // Comments list
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.isLoading {
                        ForEach(0..<3, id: \.self) { _ in
                            CommentSkeletonView()
                        }
                    } else if viewModel.comments.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.topLevelComments) { comment in
                            CommentThreadView(
                                comment: comment,
                                replies: viewModel.replies(for: comment.id),
                                allReplies: viewModel.comments,
                                depth: 0,
                                onReply: { replyingTo = $0 },
                                onVote: { viewModel.vote(commentId: $0, isUpvote: $1) }
                            )
                        }
                    }
                }
                .padding(.bottom, 100)
            }

            // Comment input
            commentInput
        }
        .navigationTitle("Discussion")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadComments()
        }
    }

    private var sortHeader: some View {
        HStack {
            Text("\(viewModel.comments.count) Comments")
                .font(.subheadline.weight(.medium))

            Spacer()

            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        sortOption = option
                        viewModel.sort(by: option)
                    } label: {
                        Label(option.rawValue, systemImage: option.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: sortOption.icon)
                    Text(sortOption.rawValue)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))

            Text("No discussions yet")
                .font(.headline)

            Text("Be the first to start a conversation about this event!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private var commentInput: some View {
        VStack(spacing: 0) {
            Divider()

            if let replyTo = replyingTo {
                HStack {
                    Text("Replying to \(replyTo.authorName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        replyingTo = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            HStack(spacing: 12) {
                TextField(replyingTo != nil ? "Write a reply..." : "Add a comment...", text: $newComment, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .focused($isCommentFocused)

                Button {
                    submitComment()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(newComment.isEmpty ? .gray : .green)
                }
                .disabled(newComment.isEmpty)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    private func submitComment() {
        guard !newComment.isEmpty else { return }

        Task {
            await viewModel.addComment(
                content: newComment,
                parentId: replyingTo?.id
            )
            newComment = ""
            replyingTo = nil
            isCommentFocused = false
        }
    }
}

// MARK: - Comment Thread View (Recursive)

struct CommentThreadView: View {
    let comment: EventComment
    let replies: [EventComment]
    let allReplies: [EventComment]
    let depth: Int
    let onReply: (EventComment) -> Void
    let onVote: (String, Bool) -> Void

    @State private var isCollapsed = false
    @State private var showAllReplies = false

    private let maxDepth = 4
    private var indentWidth: CGFloat { CGFloat(min(depth, maxDepth)) * 16 }
    private var displayReplies: [EventComment] {
        showAllReplies ? replies : Array(replies.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main comment
            HStack(alignment: .top, spacing: 8) {
                // Collapse indicator for nested comments
                if depth > 0 {
                    Rectangle()
                        .fill(threadColor)
                        .frame(width: 2)
                        .padding(.leading, indentWidth - 16)
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Author row
                    HStack(spacing: 8) {
                        // Avatar
                        AsyncImage(url: URL(string: comment.authorPhotoURL ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())

                        // Author name
                        Text(comment.authorName)
                            .font(.subheadline.weight(.medium))

                        if comment.isOrganizer {
                            Text("OP")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }

                        if comment.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        Text(comment.createdAt.timeAgo())
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if comment.editedAt != nil {
                            Text("(edited)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Content
                    if !isCollapsed {
                        Text(comment.content)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)

                        // Actions row
                        HStack(spacing: 16) {
                            // Voting
                            HStack(spacing: 4) {
                                Button {
                                    onVote(comment.id, true)
                                } label: {
                                    Image(systemName: "arrow.up")
                                        .font(.caption)
                                }

                                Text("\(comment.score)")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(scoreColor)

                                Button {
                                    onVote(comment.id, false)
                                } label: {
                                    Image(systemName: "arrow.down")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.secondary)

                            // Reply button
                            Button {
                                onReply(comment)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.left")
                                    Text("Reply")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }

                            // More options
                            Menu {
                                Button("Share", systemImage: "square.and.arrow.up") {}
                                Button("Report", systemImage: "flag") {}
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.leading, depth > 0 ? 0 : indentWidth)
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .contentShape(Rectangle())
            .onTapGesture {
                if comment.replyCount > 0 {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCollapsed.toggle()
                    }
                }
            }

            // Nested replies (recursive)
            if !isCollapsed && !replies.isEmpty && depth < maxDepth {
                ForEach(displayReplies) { reply in
                    CommentThreadView(
                        comment: reply,
                        replies: allReplies.filter { $0.parentId == reply.id },
                        allReplies: allReplies,
                        depth: depth + 1,
                        onReply: onReply,
                        onVote: onVote
                    )
                }

                // Show more replies button
                if replies.count > 3 && !showAllReplies {
                    Button {
                        showAllReplies = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.turn.down.right")
                            Text("Show \(replies.count - 3) more replies")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.leading, indentWidth + 24)
                        .padding(.vertical, 8)
                    }
                }
            }

            // Collapsed indicator
            if isCollapsed && comment.replyCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.down")
                    Text("\(comment.replyCount) replies hidden")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, indentWidth + 40)
                .padding(.bottom, 8)
            }

            Divider()
                .padding(.leading, indentWidth + 16)
        }
    }

    private var threadColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink]
        return colors[depth % colors.count]
    }

    private var scoreColor: Color {
        if comment.score > 0 { return .orange }
        if comment.score < 0 { return .blue }
        return .secondary
    }
}

// MARK: - Comment Skeleton

struct CommentSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 24, height: 24)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 12)
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 16)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 200, height: 16)
        }
        .padding()
        .shimmer()
    }
}

// MARK: - View Model

@MainActor
class EventForumViewModel: ObservableObject {
    let eventId: String

    @Published var comments: [EventComment] = []
    @Published var isLoading = false
    @Published var error: String?

    private let firestoreService = FirestoreService.shared

    var topLevelComments: [EventComment] {
        comments.filter { $0.parentId == nil }
    }

    func replies(for commentId: String) -> [EventComment] {
        comments.filter { $0.parentId == commentId }
    }

    init(eventId: String) {
        self.eventId = eventId
    }

    func loadComments() {
        isLoading = true

        Task {
            do {
                comments = try await firestoreService.getEventComments(eventId: eventId)
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }

    func addComment(content: String, parentId: String?) async {
        guard let currentUser = UserState.shared.currentUser else {
            error = "Please sign in to comment"
            return
        }

        let newComment = EventComment(
            id: UUID().uuidString,
            eventId: eventId,
            parentId: parentId,
            authorId: currentUser.id,
            authorName: currentUser.displayName,
            authorPhotoURL: currentUser.photoURL,
            content: content,
            upvotes: 0,
            downvotes: 0,
            replyCount: 0,
            isOrganizer: false,
            isPinned: false,
            createdAt: Date(),
            editedAt: nil
        )

        // Optimistically add to local array
        comments.append(newComment)

        // Update parent reply count locally
        if let parentId = parentId,
           let index = comments.firstIndex(where: { $0.id == parentId }) {
            comments[index].replyCount += 1
        }

        // Save to Firestore
        do {
            try await firestoreService.saveEventComment(newComment)
        } catch {
            self.error = "Failed to save comment: \(error.localizedDescription)"
            // Remove optimistically added comment on failure
            comments.removeAll { $0.id == newComment.id }
        }
    }

    func vote(commentId: String, isUpvote: Bool) {
        guard let currentUser = UserState.shared.currentUser else { return }
        guard let index = comments.firstIndex(where: { $0.id == commentId }) else { return }

        // Optimistically update UI
        if isUpvote {
            comments[index].upvotes += 1
        } else {
            comments[index].downvotes += 1
        }

        // Save to Firestore
        Task {
            do {
                try await firestoreService.voteOnEventComment(
                    commentId: commentId,
                    userId: currentUser.id,
                    isUpvote: isUpvote
                )
            } catch {
                // Revert on failure
                if isUpvote {
                    comments[index].upvotes -= 1
                } else {
                    comments[index].downvotes -= 1
                }
                self.error = "Failed to save vote"
            }
        }
    }

    func sort(by option: EventForumView.SortOption) {
        switch option {
        case .hot:
            // Score / time decay
            comments.sort { $0.score > $1.score }
        case .new:
            comments.sort { $0.createdAt > $1.createdAt }
        case .top:
            comments.sort { $0.upvotes > $1.upvotes }
        }
    }
}

#Preview {
    NavigationStack {
        EventForumView(event: .preview)
    }
}
