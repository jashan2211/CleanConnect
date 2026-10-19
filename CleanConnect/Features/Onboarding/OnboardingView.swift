import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(LocationService.self) private var location
    @State private var page = 0

    private struct Page {
        let icon: String
        let accent: String
        let title: LocalizedStringKey
        let body: LocalizedStringKey
        let tint: Color
    }

    private let pages: [Page] = [
        Page(icon: "camera.fill", accent: "mappin.and.ellipse", title: "Spot it. Snap it.",
             body: "See a garbage dump, a blocked drain or a littered park? Report it in 10 seconds with a photo. It goes on the live map for your whole city.",
             tint: .ccDirty),
        Page(icon: "sparkles", accent: "arrow.left.and.right", title: "Clean it. Prove it.",
             body: "Claim a spot, clean it, and post the after photo. Your before/after goes in the feed and earns you Swachh Points.",
             tint: .ccGreen),
        Page(icon: "person.3.fill", accent: "flag.fill", title: "Rally your mohalla.",
             body: "Start a cleanup drive, invite friends on WhatsApp and climb the city leaderboard together. Bharat gets cleaner one spot at a time.",
             tint: .ccSaffron),
    ]

    var body: some View {
        ZStack {
            LinearGradient.ccHero.ignoresSafeArea()
            Circle().fill(.white.opacity(0.06)).frame(width: 520).offset(x: 160, y: -300)
            Circle().fill(.white.opacity(0.05)).frame(width: 380).offset(x: -170, y: 330)

            VStack(spacing: 0) {
                HStack {
                    Image("BrandMark").resizable().frame(width: 34, height: 34)
                    Text("CleanConnect").font(.cc(.headline, weight: .heavy)).foregroundStyle(.white)
                    Spacer()
                    if page < pages.count {
                        Button("Skip") { withAnimation { page = pages.count } }
                            .font(.cc(.subheadline, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(pages[index]).tag(index)
                    }
                    locationPage.tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0...pages.count, id: \.self) { index in
                        Capsule()
                            .fill(.white.opacity(index == page ? 1 : 0.35))
                            .frame(width: index == page ? 22 : 8, height: 8)
                    }
                }
                .animation(.snappy, value: page)
                .padding(.bottom, 20)

                Button {
                    Haptics.tap()
                    if page < pages.count {
                        withAnimation { page += 1 }
                    } else {
                        location.requestPermission()
                        onFinish()
                    }
                } label: {
                    Text(page < pages.count ? "Next" : "Let's clean up India")
                }
                .buttonStyle(PrimaryButtonStyle(tint: .white, foreground: .ccGreenDeep))
                .padding(.horizontal, 24)

                if page == pages.count {
                    Button("Not now") { onFinish() }
                        .font(.cc(.subheadline, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.top, 12)
                }
            }
            .padding(.bottom, 16)
            .readableWidth(560)
        }
    }

    private func pageView(_ page: Page) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(.white.opacity(0.12)).frame(width: 230, height: 230)
                Circle().fill(.white).frame(width: 170, height: 170)
                    .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
                Image(systemName: page.icon)
                    .font(.system(size: 70, weight: .bold))
                    .foregroundStyle(page.tint)
                    .symbolEffect(.bounce, value: self.page)
                Image(systemName: page.accent)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(page.tint, in: Circle())
                    .overlay(Circle().strokeBorder(.white, lineWidth: 4))
                    .offset(x: 72, y: -66)
            }
            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.cc(.body, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }

    private var locationPage: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(.white.opacity(0.12)).frame(width: 230, height: 230)
                Circle().fill(.white).frame(width: 170, height: 170)
                    .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
                Image(systemName: "location.fill")
                    .font(.system(size: 66, weight: .bold))
                    .foregroundStyle(Color.ccBlue)
            }
            VStack(spacing: 14) {
                Text("What's near you?")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Allow location to see dirty spots and drives around you, and to pin your reports accurately. We never share your live location.")
                    .font(.cc(.body, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }
}
