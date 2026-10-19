import SwiftUI
import FirebaseFirestore

/// Comments under a spot or drive, with an inline composer.
struct CommentsSection: View {
    let parent: DocumentReference
    let count: Int
    var title: LocalizedStringKey = "Comments"
    var onFlag: (Comment) -> Void

    @Environment(Session.self) private var session
    @State private var comments: [Comment] = []
    @State private var text = ""
    @State private var sending = false
    @FocusState private var focused: Bool

    private var visible: [Comment] { comments.filter { !session.isBlocked($0.authorId) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title).font(.ccTitle3).foregroundStyle(Color.ccInk)
                if !visible.isEmpty {
                    Text("\(visible.count)").font(.ccNumber(15)).foregroundStyle(Color.ccInk2)
                }
            }

            if visible.isEmpty {
                Text("No comments yet. Say something encouraging!")
                    .font(.cc(.subheadline)).foregroundStyle(Color.ccInk2)
            }

            ForEach(visible) { comment in
                HStack(alignment: .top, spacing: 10) {
                    NavigationLink(value: Route.profile(comment.authorId)) {
                        Avatar(url: comment.authorPhoto, name: comment.authorName, size: 34)
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(comment.authorName).font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk)
                            Text(Fmt.relative(comment.createdAt)).font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                        }
                        Text(comment.text).font(.cc(.subheadline)).foregroundStyle(Color.ccInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Menu {
                        if comment.authorId == session.uid {
                            Button(role: .destructive) {
                                Task { try? await CommentAPI.delete(comment, parent: parent) }
                            } label: { Label("Delete", systemImage: "trash") }
                        } else if session.isSignedIn {
                            Button { onFlag(comment) } label: { Label("Report comment", systemImage: "flag") }
                            Button(role: .destructive) {
                                Task { await session.block(comment.authorId) }
                            } label: { Label("Block \(comment.authorName)", systemImage: "hand.raised") }
                        }
                    } label: {
                        Image(systemName: "ellipsis").foregroundStyle(Color.ccInk2).frame(width: 30, height: 30)
                    }
                }
            }

            HStack(spacing: 10) {
                TextField(session.isSignedIn ? "Add a comment…" : "Sign in to comment", text: $text, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($focused)
                    .disabled(!session.isSignedIn)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.ccSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.ccStroke))
                    .onTapGesture { if !session.isSignedIn { session.gate("Sign in to join the conversation.") } }
                Button(action: send) {
                    Image(systemName: sending ? "hourglass" : "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(text.trimmed.isEmpty ? Color.ccInk2.opacity(0.4) : Color.ccGreen, in: Circle())
                }
                .disabled(text.trimmed.isEmpty || sending)
                .accessibilityLabel(Text("Send comment"))
            }
        }
        .task {
            for await list in CommentAPI.comments(parent: parent) { comments = list }
        }
    }

    private func send() {
        guard session.gate("Sign in to join the conversation."), let profile = session.profile else { return }
        let body = text
        sending = true
        Task {
            do {
                try await CommentAPI.add(body, parent: parent, by: profile)
                text = ""
                focused = false
            } catch {
                session.show(error: error)
            }
            sending = false
        }
    }
}

/// Report objectionable content. Required for user-generated content (App Store guideline 1.2).
struct FlagSheet: View {
    let target: FlagTarget
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var reason: String?
    @State private var details = ""
    @State private var sending = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(Moderation.reasons, id: \.self) { item in
                        Button {
                            reason = item
                        } label: {
                            HStack {
                                Text(item).foregroundStyle(Color.ccInk)
                                Spacer()
                                if reason == item { Image(systemName: "checkmark").foregroundStyle(Color.ccGreen) }
                            }
                        }
                    }
                } header: {
                    Text("What's wrong?")
                } footer: {
                    Text("Our team reviews every report within 24 hours and removes content that breaks the community guidelines. Content reported by several people is hidden automatically.")
                }
                Section("More details (optional)") {
                    TextField("Tell us more", text: $details, axis: .vertical).lineLimit(2...5)
                }
            }
            .navigationTitle("Report content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        guard let reason else { return }
                        sending = true
                        Task {
                            do {
                                try await Moderation.flag(target, reason: details.trimmed.isEmpty ? reason : "\(reason): \(details.trimmed)")
                                session.show(String(localized: "Thanks. We'll review it within 24 hours."), icon: "flag.fill")
                                dismiss()
                            } catch {
                                session.show(error: error)
                            }
                            sending = false
                        }
                    }
                    .disabled(reason == nil || sending)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
