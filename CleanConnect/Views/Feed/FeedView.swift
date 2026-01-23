// FeedView.swift
// Main feed displaying cleanup posts

import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var showCreatePost = false
    @State private var selectedFilter: PostFilter = .all

    enum PostFilter: String, CaseIterable {
        case all = "All"
        case myState = "My State"
        case myDistrict = "My District"
        case following = "Following"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Filter chips
                    filterChips
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                    // Posts list
                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        Spacer()
                        ProgressView("Loading posts...")
                        Spacer()
                    } else if viewModel.posts.isEmpty {
                        emptyState
                    } else {
                        postsList
                    }
                }

                // Floating action button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        createPostButton
                            .padding()
                    }
                }
            }
            .navigationTitle("CleanConnect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: LeaderboardView()) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(onPostCreated: {
                    viewModel.refresh()
                })
            }
            .refreshable {
                await viewModel.refreshAsync()
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PostFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        viewModel.applyFilter(filter)
                    }
                }
            }
        }
    }

    private var postsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.posts) { post in
                    NavigationLink(destination: PostDetailView(post: post)) {
                        PostCard(post: post)
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.hasMorePosts {
                    ProgressView()
                        .onAppear {
                            viewModel.loadMore()
                        }
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "leaf.arrow.triangle.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.green.opacity(0.5))
            Text("No cleanup posts yet")
                .font(.headline)
            Text("Be the first to share your cleanup effort!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Create Post") {
                showCreatePost = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            Spacer()
        }
        .padding()
    }

    private var createPostButton: some View {
        Button(action: { showCreatePost = true }) {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "22C55E"), Color(hex: "16A34A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color.secondary.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

#Preview {
    FeedView()
}
