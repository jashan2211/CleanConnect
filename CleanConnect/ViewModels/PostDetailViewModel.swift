// PostDetailViewModel.swift
// View model for post detail view

import Foundation
import Combine

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false

    private let postId: String

    init(postId: String) {
        self.postId = postId
        loadComments()
    }

    func loadComments() {
        Task {
            isLoading = true
            do {
                comments = try await PostService.shared.getComments(postId: postId)
            } catch {
                print("Error loading comments: \(error)")
            }
            isLoading = false
        }
    }

    func addComment(_ text: String) async {
        guard let userId = AuthManager.shared.currentUserId,
              let user = UserState.shared.currentUser else { return }

        do {
            let comment = try await PostService.shared.addComment(
                postId: postId,
                userId: userId,
                userName: user.displayName,
                userPhotoURL: user.photoURL,
                text: text
            )
            comments.append(comment)
        } catch {
            print("Error adding comment: \(error)")
        }
    }
}
