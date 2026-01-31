// FeedView.swift
// Main feed displaying cleanup posts - Reddit-style engaging design

import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var showCreatePost = false
    @State private var selectedFilter: PostFilter = .all
    @State private var showSortOptions = false
    @State private var selectedSort: SortOption = .hot

    enum PostFilter: String, CaseIterable {
        case all = "All India"
        case myState = "My State"
        case myDistrict = "My District"
        case following = "Following"
        case verified = "Verified"

        var icon: String {
            switch self {
            case .all: return "globe.asia.australia.fill"
            case .myState: return "map.fill"
            case .myDistrict: return "mappin.circle.fill"
            case .following: return "person.2.fill"
            case .verified: return "checkmark.seal.fill"
            }
        }
    }

    enum SortOption: String, CaseIterable {
        case hot = "Hot"
        case new = "New"
        case topDay = "Top Today"
        case topWeek = "Top Week"
        case mostTipped = "Most Tipped"

        var icon: String {
            switch self {
            case .hot: return "flame.fill"
            case .new: return "clock.fill"
            case .topDay: return "chart.bar.fill"
            case .topWeek: return "calendar"
            case .mostTipped: return "indianrupeesign.circle.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Stats banner
                    statsBanner

                    // Filter & Sort bar
                    filterSortBar

                    // Posts list
                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        loadingView
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
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
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
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.yellow)
                            Text("Top")
                                .font(.subheadline.bold())
                        }
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

    // MARK: - Stats Banner
    private var statsBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(
                    icon: "leaf.fill",
                    value: "12.5K",
                    label: "kg cleaned",
                    color: .green
                )
                StatCard(
                    icon: "person.3.fill",
                    value: "2.3K",
                    label: "cleaners",
                    color: .blue
                )
                StatCard(
                    icon: "mappin.and.ellipse",
                    value: "500+",
                    label: "locations",
                    color: .orange
                )
                StatCard(
                    icon: "indianrupeesign.circle.fill",
                    value: "₹45K",
                    label: "tips given",
                    color: .purple
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Filter & Sort Bar
    private var filterSortBar: some View {
        VStack(spacing: 0) {
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PostFilter.allCases, id: \.self) { filter in
                        FeedFilterPill(
                            title: filter.rawValue,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                            viewModel.applyFilter(filter)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            // Sort dropdown
            HStack {
                Button(action: { showSortOptions.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: selectedSort.icon)
                            .font(.caption)
                        Text(selectedSort.rawValue)
                            .font(.caption.weight(.medium))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                .confirmationDialog("Sort by", isPresented: $showSortOptions) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            selectedSort = option
                            viewModel.applySort(option)
                        }
                    }
                }

                Spacer()

                Text("\(viewModel.posts.count) posts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading cleanups...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Posts List
    private var postsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.posts) { post in
                    NavigationLink(destination: PostDetailView(post: post)) {
                        PostCard(post: post)
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.hasMorePosts {
                    ProgressView()
                        .padding()
                        .onAppear {
                            viewModel.loadMore()
                        }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "leaf.arrow.triangle.circlepath")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }

            Text("No cleanups yet")
                .font(.title2.bold())

            Text("Be the first to share your cleanup effort and inspire others!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: { showCreatePost = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Share Your Cleanup")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(25)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Create Post Button
    private var createPostButton: some View {
        Button(action: { showCreatePost = true }) {
            HStack(spacing: 8) {
                Image(systemName: "video.badge.plus")
                    .font(.title3.bold())
                Text("Share")
                    .font(.subheadline.bold())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(hex: "22C55E"), Color(hex: "16A34A")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(value)
                    .font(.subheadline.bold())
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Feed Filter Pill
struct FeedFilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

// MARK: - Legacy Filter Chip (for compatibility)
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
