// FeedViewModel.swift
// View model for the feed view with advanced sorting and filtering

import Foundation
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var hasMorePosts = true
    @Published var errorMessage: String?

    // Current filter and sort settings
    private var currentFilter: FeedView.PostFilter = .all
    private var currentSort: FeedView.SortOption = .hot
    private var currentTimeRange: TimeRange = .all
    private var lastPostId: String?

    enum TimeRange: String, CaseIterable {
        case day = "day"
        case week = "week"
        case month = "month"
        case year = "year"
        case all = "all"

        var displayName: String {
            switch self {
            case .day: return "Today"
            case .week: return "This Week"
            case .month: return "This Month"
            case .year: return "This Year"
            case .all: return "All Time"
            }
        }
    }

    init() {
        loadPosts()
    }

    // MARK: - Load Posts

    func loadPosts() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Determine filter parameters
                let state: String?
                let district: String?
                let verifiedOnly: Bool

                switch currentFilter {
                case .all:
                    state = nil
                    district = nil
                    verifiedOnly = false
                case .myState:
                    state = UserState.shared.currentUser?.state
                    district = nil
                    verifiedOnly = false
                case .myDistrict:
                    state = UserState.shared.currentUser?.state
                    district = UserState.shared.currentUser?.district
                    verifiedOnly = false
                case .following:
                    // TODO: Implement following filter
                    state = nil
                    district = nil
                    verifiedOnly = false
                case .verified:
                    state = nil
                    district = nil
                    verifiedOnly = true
                }

                // Map sort option to API parameter
                let sortBy: String
                switch currentSort {
                case .hot: sortBy = "hot"
                case .new: sortBy = "new"
                case .topDay, .topWeek: sortBy = "top"
                case .mostTipped: sortBy = "tipped"
                }

                #if canImport(FirebaseFunctions)
                // Use Cloud Functions for advanced sorting
                let result = try await CloudFunctionsService.shared.getFeedPosts(
                    sortBy: sortBy,
                    timeRange: currentTimeRange.rawValue,
                    state: state,
                    district: district,
                    verifiedOnly: verifiedOnly,
                    limit: 20,
                    startAfter: nil
                )

                posts = result.posts
                hasMorePosts = result.hasMore
                lastPostId = result.lastPostId
                #else
                // Fallback to basic loading
                var newPosts = try await PostService.shared.getPosts(
                    state: state,
                    district: district
                )

                // Apply local filtering
                if verifiedOnly {
                    newPosts = newPosts.filter { $0.hasVideoProof || $0.communityVotes >= 10 }
                }

                // Apply local sorting
                switch currentSort {
                case .new:
                    newPosts.sort { $0.createdAt > $1.createdAt }
                case .topDay, .topWeek:
                    newPosts.sort { ($0.communityVotes - $0.communityDownvotes) > ($1.communityVotes - $1.communityDownvotes) }
                case .mostTipped:
                    newPosts.sort { $0.tipsReceived > $1.tipsReceived }
                case .hot:
                    // Hot = combination of recency and votes
                    newPosts.sort { post1, post2 in
                        let score1 = Double(post1.communityVotes - post1.communityDownvotes) + (Date().timeIntervalSince(post1.createdAt) < 86400 ? 10 : 0)
                        let score2 = Double(post2.communityVotes - post2.communityDownvotes) + (Date().timeIntervalSince(post2.createdAt) < 86400 ? 10 : 0)
                        return score1 > score2
                    }
                }

                // Apply time range filter locally
                if currentTimeRange != .all {
                    let cutoff: Date
                    switch currentTimeRange {
                    case .day:
                        cutoff = Date().addingTimeInterval(-86400)
                    case .week:
                        cutoff = Date().addingTimeInterval(-604800)
                    case .month:
                        cutoff = Date().addingTimeInterval(-2592000)
                    case .year:
                        cutoff = Date().addingTimeInterval(-31536000)
                    case .all:
                        cutoff = Date.distantPast
                    }
                    newPosts = newPosts.filter { $0.createdAt >= cutoff }
                }

                posts = newPosts
                hasMorePosts = newPosts.count >= 20
                #endif
            } catch {
                print("Error loading posts: \(error)")
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Load More (Pagination)

    func loadMore() {
        guard !isLoading, hasMorePosts, let lastId = lastPostId else { return }
        isLoading = true

        Task {
            do {
                #if canImport(FirebaseFunctions)
                let result = try await CloudFunctionsService.shared.getFeedPosts(
                    sortBy: currentSort == .new ? "new" : (currentSort == .mostTipped ? "tipped" : "top"),
                    timeRange: currentTimeRange.rawValue,
                    limit: 20,
                    startAfter: lastId
                )

                posts.append(contentsOf: result.posts)
                hasMorePosts = result.hasMore
                lastPostId = result.lastPostId
                #endif
            } catch {
                print("Error loading more posts: \(error)")
            }
            isLoading = false
        }
    }

    // MARK: - Refresh

    func refresh() {
        posts = []
        hasMorePosts = true
        lastPostId = nil
        loadPosts()
    }

    func refreshAsync() async {
        posts = []
        hasMorePosts = true
        lastPostId = nil

        do {
            #if canImport(FirebaseFunctions)
            let result = try await CloudFunctionsService.shared.getFeedPosts(
                sortBy: "new",
                timeRange: "all",
                limit: 20
            )
            posts = result.posts
            hasMorePosts = result.hasMore
            lastPostId = result.lastPostId
            #else
            let newPosts = try await PostService.shared.getPosts()
            posts = newPosts
            hasMorePosts = newPosts.count >= 20
            #endif
        } catch {
            print("Error refreshing: \(error)")
        }
    }

    // MARK: - Filters & Sorting

    func applyFilter(_ filter: FeedView.PostFilter) {
        currentFilter = filter
        refresh()
    }

    func applySort(_ sort: FeedView.SortOption) {
        currentSort = sort

        // Adjust time range based on sort option
        switch sort {
        case .topDay:
            currentTimeRange = .day
        case .topWeek:
            currentTimeRange = .week
        default:
            break // Keep current time range
        }

        refresh()
    }

    func applyTimeRange(_ timeRange: TimeRange) {
        currentTimeRange = timeRange
        refresh()
    }

    // MARK: - Voting

    func vote(on post: Post, voteType: String) async {
        do {
            let result = try await PostService.shared.voteOnPost(postId: post.id, voteType: voteType)

            // Update the post in our local array
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index].communityVotes = result.communityVotes
                posts[index].communityDownvotes = result.communityDownvotes
            }
        } catch {
            print("Error voting: \(error)")
            errorMessage = "Failed to register vote"
        }
    }

    // MARK: - Delete

    func deletePost(_ post: Post) async -> Bool {
        do {
            try await PostService.shared.deletePost(postId: post.id)

            // Remove from local array
            posts.removeAll { $0.id == post.id }
            return true
        } catch {
            print("Error deleting post: \(error)")
            errorMessage = "Failed to delete post"
            return false
        }
    }
}
