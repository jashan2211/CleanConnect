import SwiftUI
import AuthenticationServices

struct SignInSheet: View {
    let reason: LocalizedStringKey
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var working = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 22) {
            Capsule().fill(Color.ccStroke).frame(width: 40, height: 5).padding(.top, 10)

            Image("BrandMark")
                .resizable()
                .frame(width: 76, height: 76)
                .shadow(color: Color.ccGreen.opacity(0.35), radius: 16, y: 8)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text("Join the Swachh squad")
                    .font(.ccTitle)
                    .foregroundStyle(Color.ccInk)
                Text(reason)
                    .font(.cc(.subheadline))
                    .foregroundStyle(Color.ccInk2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            HStack(spacing: 18) {
                perk("camera.fill", "Report spots")
                perk("sparkles", "Earn points")
                perk("person.3.fill", "Join drives")
            }

            VStack(spacing: 12) {
                SignInWithAppleButton(.continue) { request in
                    session.prepareAppleRequest(request)
                } onCompletion: { result in
                    run { try await session.completeApple(result) }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52)
                .clipShape(Capsule())

                Button {
                    run { try await session.signInWithGoogle() }
                } label: {
                    HStack(spacing: 10) {
                        GoogleLogo().frame(width: 20, height: 20)
                        Text("Continue with Google")
                            .font(.system(size: 19, weight: .medium))
                    }
                    .foregroundStyle(Color.ccInk)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.ccSurface, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.ccInk.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .disabled(working)
            .overlay { if working { ProgressView() } }
            .padding(.horizontal, 24)

            if let errorMessage {
                Text(errorMessage)
                    .font(.cc(.footnote, weight: .medium))
                    .foregroundStyle(Color.ccDirty)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Text("By continuing you agree to our [Terms](\(AppConfig.termsURL.absoluteString)), [Community Guidelines](\(AppConfig.guidelinesURL.absoluteString)) and [Privacy Policy](\(AppConfig.privacyURL.absoluteString)). There's zero tolerance for abusive content or users.")
                .font(.cc(.caption))
                .foregroundStyle(Color.ccInk2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button("Maybe later") { dismiss() }
                .font(.cc(.subheadline, weight: .semibold))
                .foregroundStyle(Color.ccInk2)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: 480)
        .presentationDetents([.large])
        .presentationBackground(Color.ccBackground)
    }

    private func perk(_ icon: String, _ title: LocalizedStringKey) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.ccGreen)
                .frame(width: 46, height: 46)
                .background(Color.ccMint, in: Circle())
            Text(title).font(.ccCaption).foregroundStyle(Color.ccInk2)
        }
        .frame(maxWidth: 100)
    }

    private func run(_ work: @escaping () async throws -> Void) {
        working = true
        errorMessage = nil
        Task {
            do {
                try await work()
            } catch {
                errorMessage = error.localizedDescription
                Haptics.warning()
            }
            working = false
        }
    }
}

/// Google "G" mark drawn from its four arcs (per Google's sign-in branding).
struct GoogleLogo: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let line = s * 0.2
            let r = (s - line) / 2
            let c = CGPoint(x: s / 2, y: s / 2)
            ZStack {
                arc(c, r, from: 225, to: 315).stroke(Color(hex: 0xEA4335), style: StrokeStyle(lineWidth: line))
                arc(c, r, from: 135, to: 225).stroke(Color(hex: 0xFBBC05), style: StrokeStyle(lineWidth: line))
                arc(c, r, from: 45, to: 135).stroke(Color(hex: 0x34A853), style: StrokeStyle(lineWidth: line))
                arc(c, r, from: 0, to: 45).stroke(Color(hex: 0x4285F4), style: StrokeStyle(lineWidth: line))
                Rectangle().fill(Color(hex: 0x4285F4))
                    .frame(width: s / 2, height: line)
                    .position(x: s * 0.75, y: s / 2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func arc(_ c: CGPoint, _ r: CGFloat, from: Double, to: Double) -> Path {
        Path { p in p.addArc(center: c, radius: r, startAngle: .degrees(from), endAngle: .degrees(to), clockwise: false) }
    }
}
