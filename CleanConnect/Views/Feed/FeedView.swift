// FeedView.swift
// Main feed displaying cleanup posts - Enhanced with better filters

import SwiftUI
import CoreLocation

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @State private var showCreatePost = false
    @State private var showFilterSheet = false

    // Filter states
    @State private var selectedLocationFilter: LocationFilter = .all
    @State private var selectedTimeFilter: TimeFilter = .all
    @State private var selectedCategoryFilter: CategoryFilter = .all
    @State private var verifiedOnly = false
    @State private var selectedSort: SortOption = .hot

    enum LocationFilter: String, CaseIterable {
        case all = "All India"
        case myState = "My State"
        case myDistrict = "My District"
        case nearby = "Nearby"

        var icon: String {
            switch self {
            case .all: return "globe.asia.australia.fill"
            case .myState: return "map.fill"
            case .myDistrict: return "mappin.circle.fill"
            case .nearby: return "location.fill"
            }
        }
    }

    enum TimeFilter: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"

        var icon: String {
            switch self {
            case .all: return "infinity"
            case .today: return "sun.max.fill"
            case .week: return "calendar"
            case .month: return "calendar.badge.clock"
            }
        }
    }

    enum CategoryFilter: String, CaseIterable {
        case all = "All Types"
        case beach = "Beach"
        case park = "Park"
        case street = "Street"
        case drain = "Drain"
        case lake = "Lake/River"
        case mountain = "Mountain"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2.fill"
            case .beach: return "water.waves"
            case .park: return "tree.fill"
            case .street: return "road.lanes"
            case .drain: return "drop.fill"
            case .lake: return "drop.triangle.fill"
            case .mountain: return "mountain.2.fill"
            }
        }

        var color: Color {
            switch self {
            case .all: return .green
            case .beach: return .cyan
            case .park: return .green
            case .street: return .gray
            case .drain: return .blue
            case .lake: return .teal
            case .mountain: return .brown
            }
        }
    }

    enum SortOption: String, CaseIterable {
        case hot = "Hot"
        case new = "New"
        case topDay = "Top Today"
        case topWeek = "Top Week"
        case mostTipped = "Most Tipped"
        case nearby = "Nearby"

        var icon: String {
            switch self {
            case .hot: return "flame.fill"
            case .new: return "clock.fill"
            case .topDay: return "chart.bar.fill"
            case .topWeek: return "calendar"
            case .mostTipped: return "indianrupeesign.circle.fill"
            case .nearby: return "location.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Quick filters bar
                    quickFiltersBar

                    // Active filters indicator
                    if hasActiveFilters {
                        activeFiltersBar
                    }

                    // Posts content
                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        loadingView
                    } else if filteredPosts.isEmpty {
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
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasActiveFilters ? .green : .primary)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    sortMenu
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(onPostCreated: {
                    viewModel.refresh()
                })
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
            .refreshable {
                await viewModel.refreshAsync()
            }
        }
    }

    // MARK: - Computed Properties
    private var hasActiveFilters: Bool {
        selectedLocationFilter != .all ||
        selectedTimeFilter != .all ||
        selectedCategoryFilter != .all ||
        verifiedOnly
    }

    private var filteredPosts: [Post] {
        var posts = viewModel.posts

        // Apply category filter
        if selectedCategoryFilter != .all {
            posts = posts.filter { post in
                post.description.localizedCaseInsensitiveContains(selectedCategoryFilter.rawValue)
            }
        }

        // Apply verified filter
        if verifiedOnly {
            posts = posts.filter { $0.hasVideoProof || $0.communityVotes >= 10 }
        }

        // Apply time filter
        switch selectedTimeFilter {
        case .today:
            posts = posts.filter { Calendar.current.isDateInToday($0.createdAt) }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            posts = posts.filter { $0.createdAt >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            posts = posts.filter { $0.createdAt >= monthAgo }
        case .all:
            break
        }

        // Apply sorting
        switch selectedSort {
        case .new:
            posts.sort { $0.createdAt > $1.createdAt }
        case .hot:
            posts.sort { ($0.communityVotes + $0.tipsReceived/10) > ($1.communityVotes + $1.tipsReceived/10) }
        case .topDay, .topWeek:
            posts.sort { $0.communityVotes > $1.communityVotes }
        case .mostTipped:
            posts.sort { $0.tipsReceived > $1.tipsReceived }
        case .nearby:
            if let userLocation = locationManager.location {
                posts.sort { post1, post2 in
                    let dist1 = distance(from: userLocation, to: post1)
                    let dist2 = distance(from: userLocation, to: post2)
                    return dist1 < dist2
                }
            }
        }

        return posts
    }

    private func distance(from location: CLLocation, to post: Post) -> Double {
        guard let lat = post.latitude, let lng = post.longitude else {
            return Double.infinity
        }
        let postLocation = CLLocation(latitude: lat, longitude: lng)
        return location.distance(from: postLocation)
    }

    // MARK: - Quick Filters Bar
    private var quickFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Location filters
                ForEach(LocationFilter.allCases, id: \.self) { filter in
                    FeedFilterButton(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: selectedLocationFilter == filter,
                        color: .blue
                    ) {
                        selectedLocationFilter = filter
                        applyFilters()
                    }
                }

                Divider()
                    .frame(height: 24)

                // Verified toggle
                FeedFilterButton(
                    title: "Verified",
                    icon: "checkmark.seal.fill",
                    isSelected: verifiedOnly,
                    color: .green
                ) {
                    verifiedOnly.toggle()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Active Filters Bar
    private var activeFiltersBar: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if selectedTimeFilter != .all {
                        ActiveFilterChip(
                            title: selectedTimeFilter.rawValue,
                            icon: selectedTimeFilter.icon
                        ) {
                            selectedTimeFilter = .all
                        }
                    }

                    if selectedCategoryFilter != .all {
                        ActiveFilterChip(
                            title: selectedCategoryFilter.rawValue,
                            icon: selectedCategoryFilter.icon
                        ) {
                            selectedCategoryFilter = .all
                        }
                    }
                }
                .padding(.horizontal)
            }

            Button("Clear All") {
                clearFilters()
            }
            .font(.caption.bold())
            .foregroundColor(.red)
            .padding(.trailing)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    // MARK: - Sort Menu
    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    selectedSort = option
                } label: {
                    Label(option.rawValue, systemImage: option.icon)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedSort.icon)
                    .font(.caption)
                Text(selectedSort.rawValue)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
    }

    // MARK: - Filter Sheet
    private var filterSheet: some View {
        NavigationStack {
            List {
                // Time Filter
                Section("Time Period") {
                    ForEach(TimeFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedTimeFilter = filter
                        } label: {
                            HStack {
                                Label(filter.rawValue, systemImage: filter.icon)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedTimeFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }

                // Category Filter
                Section("Cleanup Type") {
                    ForEach(CategoryFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedCategoryFilter = filter
                        } label: {
                            HStack {
                                Label(filter.rawValue, systemImage: filter.icon)
                                    .foregroundColor(filter.color)
                                Spacer()
                                if selectedCategoryFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }

                // Verified Toggle
                Section {
                    Toggle(isOn: $verifiedOnly) {
                        Label("Verified Posts Only", systemImage: "checkmark.seal.fill")
                    }
                    .tint(.green)
                } footer: {
                    Text("Show only posts with video proof or 10+ community votes")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        clearFilters()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showFilterSheet = false
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
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
                // Post count
                HStack {
                    Text("\(filteredPosts.count) posts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)

                ForEach(filteredPosts) { post in
                    NavigationLink(destination: PostDetailView(post: post)) {
                        PostCard(post: post)
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.hasMorePosts && !hasActiveFilters {
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

                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle" : "leaf.arrow.triangle.circlepath")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }

            Text(hasActiveFilters ? "No matching posts" : "No cleanups yet")
                .font(.title2.bold())

            Text(hasActiveFilters ? "Try adjusting your filters to see more posts" : "Be the first to share your cleanup effort!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if hasActiveFilters {
                Button("Clear Filters") {
                    clearFilters()
                }
                .font(.headline)
                .foregroundColor(.green)
            } else {
                Button(action: { showCreatePost = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Share Your Cleanup")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .cornerRadius(25)
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Create Post Button
    private var createPostButton: some View {
        Button(action: { showCreatePost = true }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title3.bold())
                Text("Post")
                    .font(.subheadline.bold())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.green)
            .clipShape(Capsule())
            .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Helper Methods
    private func applyFilters() {
        switch selectedLocationFilter {
        case .all:
            viewModel.applyFilter(.all)
        case .myState:
            viewModel.applyFilter(.myState)
        case .myDistrict:
            viewModel.applyFilter(.myDistrict)
        case .nearby:
            locationManager.requestLocation()
            viewModel.applyFilter(.all)
        }
    }

    private func clearFilters() {
        selectedLocationFilter = .all
        selectedTimeFilter = .all
        selectedCategoryFilter = .all
        verifiedOnly = false
        viewModel.applyFilter(.all)
    }
}

// MARK: - Feed Filter Pill
struct FeedFilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
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
            .background(isSelected ? color : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

// MARK: - Active Filter Chip
struct ActiveFilterChip: View {
    let title: String
    let icon: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
                .font(.caption.weight(.medium))
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.2))
        .foregroundColor(.green)
        .cornerRadius(14)
    }
}

// MARK: - Legacy Support
struct FeedFilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        FeedFilterButton(title: title, icon: icon, isSelected: isSelected, color: .green, action: action)
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

#Preview {
    FeedView()
}
