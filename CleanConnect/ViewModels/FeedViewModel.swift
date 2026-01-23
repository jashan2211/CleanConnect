// FeedViewModel.swift
// View model for the feed view

import Foundation
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var hasMorePosts = true

    private var currentFilter: FeedView.PostFilter = .all

    init() {
        loadPosts()
    }

    func loadPosts() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                let newPosts = try await PostService.shared.getPosts(
                    state: currentFilter == .myState ? UserState.shared.currentUser?.state : nil,
                    district: currentFilter == .myDistrict ? UserState.shared.currentUser?.district : nil
                )

                posts = newPosts
                hasMorePosts = newPosts.count >= 20
            } catch {
                print("Error loading posts: \(error)")
            }
            isLoading = false
        }
    }

    func loadMore() {
        // Local storage doesn't need pagination for now
    }

    func refresh() {
        posts = []
        hasMorePosts = true
        loadPosts()
    }

    func refreshAsync() async {
        posts = []
        hasMorePosts = true

        do {
            let newPosts = try await PostService.shared.getPosts()
            posts = newPosts
            hasMorePosts = newPosts.count >= 20
        } catch {
            print("Error refreshing: \(error)")
        }
    }

    func applyFilter(_ filter: FeedView.PostFilter) {
        currentFilter = filter
        refresh()
    }
}
