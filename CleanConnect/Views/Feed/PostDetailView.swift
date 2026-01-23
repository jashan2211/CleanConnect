// PostDetailView.swift
// Detailed view of a cleanup post

import SwiftUI

struct PostDetailView: View {
    let post: Post
    @StateObject private var viewModel: PostDetailViewModel
    @State private var newComment = ""
    @State private var showTipSheet = false

    init(post: Post) {
        self.post = post
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(postId: post.id))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // User header
                userHeader

                // Images carousel
                imageCarousel

                // Actions bar
                actionsBar

                // Stats
                statsSection

                // Description
                if !post.description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(post.description)
                            .font(.body)
                    }
                }

                // Location
                locationSection

                Divider()

                // Comments section
                commentsSection
            }
            .padding()
        }
        .navigationTitle("Cleanup Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {}) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button(action: {}) {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showTipSheet) {
            TipSheet(post: post)
        }
    }

    private var userHeader: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: post.userPhotoURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(post.userName)
                        .font(.headline)
                    if post.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            // User level badge
            VStack(spacing: 2) {
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Eco Scout")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var imageCarousel: some View {
        TabView {
            if let beforeURL = post.beforeImageURL {
                imageView(url: beforeURL, label: "Before")
            }
            if let afterURL = post.afterImageURL {
                imageView(url: afterURL, label: "After")
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 300)
        .cornerRadius(16)
    }

    private func imageView(url: String, label: String) -> some View {
        ZStack(alignment: .topLeading) {
            AsyncImage(url: URL(string: url)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(ProgressView())
            }
            .frame(maxWidth: .infinity)
            .clipped()

            Text(label)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .padding(12)
        }
    }

    private var actionsBar: some View {
        HStack(spacing: 0) {
            ActionButton(icon: "heart", label: "\(post.likes)", isActive: post.isLiked, activeColor: .red) {}
            ActionButton(icon: "bubble.left", label: "\(post.comments)", isActive: false, activeColor: .blue) {}
            ActionButton(icon: "indianrupeesign.circle", label: "Tip", isActive: false, activeColor: .green) {
                showTipSheet = true
            }
            ActionButton(icon: "square.and.arrow.up", label: "Share", isActive: false, activeColor: .gray) {}
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var statsSection: some View {
        HStack(spacing: 24) {
            StatItem(icon: "trash.fill", value: "\(String(format: "%.1f", post.wasteCollectedKg)) kg", label: "Collected", color: .orange)
            if let duration = post.durationMinutes {
                StatItem(icon: "clock.fill", value: "\(duration) min", label: "Duration", color: .blue)
            }
            StatItem(icon: "star.fill", value: "+\(post.pointsEarned)", label: "Points", color: .yellow)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.headline)
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                Text("\(post.district), \(post.state)")
                    .font(.subheadline)
            }
            // Map placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 150)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        Image(systemName: "map")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Map View")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comments (\(viewModel.comments.count))")
                .font(.headline)

            // Comment input
            HStack {
                TextField("Add a comment...", text: $newComment)
                    .textFieldStyle(.roundedBorder)
                Button(action: submitComment) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(newComment.isEmpty ? .gray : .green)
                }
                .disabled(newComment.isEmpty)
            }

            // Comments list
            ForEach(viewModel.comments) { comment in
                CommentRow(comment: comment)
            }
        }
    }

    private func submitComment() {
        guard !newComment.isEmpty else { return }
        Task {
            await viewModel.addComment(newComment)
            newComment = ""
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isActive ? "\(icon).fill" : icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isActive ? activeColor : .secondary)
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: comment.userPhotoURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.userName)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(comment.createdAt.timeAgo())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(comment.text)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        PostDetailView(post: Post.preview)
    }
}
