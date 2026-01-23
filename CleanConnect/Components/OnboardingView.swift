// OnboardingView.swift
// First-time user onboarding experience

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "leaf.circle.fill",
            title: "Clean Your Community",
            description: "Document your cleanup efforts with before & after photos. Every piece of waste collected makes a difference!",
            color: .ccIndiaGreen
        ),
        OnboardingPage(
            image: "video.fill",
            title: "Verify with Video",
            description: "Add YouTube or Instagram video links to verify your cleanups and earn bonus points. Verified posts get 3x more tips!",
            color: .ccSaffron
        ),
        OnboardingPage(
            image: "indianrupeesign.circle.fill",
            title: "Earn Tips & Rewards",
            description: "Get tipped by the community for your efforts. 95% goes directly to you. Plus earn points and climb the leaderboard!",
            color: .ccTipGold
        ),
        OnboardingPage(
            image: "person.3.fill",
            title: "Join Cleanup Events",
            description: "Organize or join community cleanup drives. Meet fellow eco-warriors and make a bigger impact together!",
            color: .blue
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [pages[currentPage].color.opacity(0.3), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.secondary)
                    .padding()
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Action button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(pages[currentPage].color)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation {
            isPresented = false
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: page.image)
                .font(.system(size: 100))
                .foregroundColor(page.color)
                .padding(32)
                .background(page.color.opacity(0.1))
                .clipShape(Circle())

            // Title
            Text(page.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Onboarding Check Modifier

struct OnboardingCheckModifier: ViewModifier {
    @State private var showOnboarding = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                    showOnboarding = true
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
    }
}

extension View {
    func withOnboarding() -> some View {
        modifier(OnboardingCheckModifier())
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
