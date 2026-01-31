// PostDetailViewModel.swift
// View model for post detail view

import Foundation
import Combine
import FirebaseAuth

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

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
        // Use Firebase Auth directly to ensure userId matches request.auth.uid
        guard let firebaseUser = Auth.auth().currentUser,
              let user = UserState.shared.currentUser else { return }

        do {
            let comment = try await PostService.shared.addComment(
                postId: postId,
                userId: firebaseUser.uid,
                userName: user.displayName,
                userPhotoURL: user.photoURL,
                text: text
            )
            comments.insert(comment, at: 0) // Add to top
        } catch {
            print("Error adding comment: \(error)")
            errorMessage = "Failed to add comment"
        }
    }

    func deleteComment(_ comment: Comment) async -> Bool {
        // Check ownership using Firebase Auth uid
        guard let firebaseUser = Auth.auth().currentUser,
              comment.userId == firebaseUser.uid else {
            errorMessage = "You can only delete your own comments"
            return false
        }

        do {
            try await PostService.shared.deleteComment(commentId: comment.id)
            comments.removeAll { $0.id == comment.id }
            return true
        } catch {
            print("Error deleting comment: \(error)")
            errorMessage = "Failed to delete comment"
            return false
        }
    }

    func canDeleteComment(_ comment: Comment) -> Bool {
        return comment.userId == Auth.auth().currentUser?.uid
    }
}
