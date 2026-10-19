import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(Session.self) private var session
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @State private var confirmSignOut = false
    @State private var confirmDelete = false
    @State private var deleting = false

    var body: some View {
        List {
            if session.isSignedIn {
                Section {
                    HStack(spacing: 12) {
                        Avatar(url: session.profile?.photoURL, name: session.profile?.name ?? "", size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.profile?.name ?? "").font(.cc(.headline, weight: .bold))
                            Text(session.email ?? String(localized: "Signed in")).font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                        }
                    }
                    NavigationLink(value: Route.blocked) { Label("Blocked people", systemImage: "hand.raised.fill") }
                } header: {
                    Text("Account")
                }
            } else {
                Section {
                    Button { session.gate("Sign in to start your Swachh profile.") } label: {
                        Label("Sign in", systemImage: "person.crop.circle.badge.plus")
                    }
                }
            }

            Section("Preferences") {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } label: {
                    Label("Language, notifications & location", systemImage: "globe")
                }
            }

            Section("Spread the word") {
                ShareLink(item: AppConfig.appStoreURL, message: Text("I'm cleaning up my city with CleanConnect. Report garbage, post before/afters and join cleanup drives. Join me!")) {
                    Label("Invite friends", systemImage: "person.2.wave.2.fill")
                }
                Button { requestReview() } label: { Label("Rate CleanConnect", systemImage: "star.fill") }
            }

            Section("Help & legal") {
                Link(destination: AppConfig.guidelinesURL) { Label("Community guidelines", systemImage: "heart.text.square.fill") }
                Link(destination: AppConfig.supportURL) { Label("Help & support", systemImage: "questionmark.circle.fill") }
                if let mail = URL(string: "mailto:\(AppConfig.supportEmail)?subject=CleanConnect%20feedback") {
                    Link(destination: mail) { Label("Email us", systemImage: "envelope.fill") }
                }
                Link(destination: AppConfig.privacyURL) { Label("Privacy policy", systemImage: "hand.raised.square.fill") }
                Link(destination: AppConfig.termsURL) { Label("Terms of use", systemImage: "doc.text.fill") }
            }

            if session.isSignedIn {
                Section {
                    Button("Sign out") { confirmSignOut = true }
                    Button("Delete account", role: .destructive) { confirmDelete = true }
                } footer: {
                    Text("Deleting your account permanently removes your profile, reports, comments and drive sign-ups. Cleanups you completed stay on the map without your name.")
                }
            }

            Section {
                VStack(spacing: 6) {
                    Image("BrandMark").resizable().frame(width: 44, height: 44)
                    Text("CleanConnect \(AppConfig.version)").font(.cc(.footnote, weight: .semibold)).foregroundStyle(Color.ccInk2)
                    Text("Made with ❤️ for a cleaner India").font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Settings")
        .tint(.ccGreen)
        .overlay {
            if deleting {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Deleting account…").padding(24).background(Color.ccSurface, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .confirmationDialog("Sign out?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { session.signOut() }
        }
        .alert("Delete your account?", isPresented: $confirmDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleting = true
                Task {
                    do {
                        try await session.deleteAccount()
                        session.show(String(localized: "Your account has been deleted."))
                    } catch {
                        session.show(error: error)
                    }
                    deleting = false
                }
            }
        } message: {
            Text("This can't be undone. Your points, badges, reports and comments will be removed.")
        }
    }
}

struct BlockedUsersView: View {
    @Environment(Session.self) private var session
    @State private var profiles: [Profile] = []

    var body: some View {
        List {
            if session.blocked.isEmpty {
                Text("You haven't blocked anyone.").foregroundStyle(Color.ccInk2)
            }
            ForEach(Array(session.blocked), id: \.self) { uid in
                HStack {
                    let profile = profiles.first { $0.id == uid }
                    Avatar(url: profile?.photoURL, name: profile?.name ?? "?", size: 36)
                    Text(profile?.name ?? String(localized: "Community member"))
                    Spacer()
                    Button("Unblock") { Task { await session.unblock(uid) } }
                        .buttonStyle(.secondary(.ccGreen, fullWidth: false))
                }
            }
        }
        .navigationTitle("Blocked people")
        .task(id: session.blocked) {
            var loaded = [Profile]()
            for uid in session.blocked {
                if let p = try? await ProfileAPI.fetch(uid) { loaded.append(p) }
            }
            profiles = loaded
        }
    }
}
