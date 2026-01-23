// ConfettiView.swift
// Celebration animations for milestones

import SwiftUI

struct ConfettiView: View {
    @Binding var isActive: Bool
    var colors: [Color] = [.ccSaffron, .ccIndiaGreen, .blue, .yellow, .pink, .purple]
    var particleCount: Int = 50

    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiParticleView(particle: particle)
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    createParticles(in: geometry.size)
                    // Auto-dismiss after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        isActive = false
                        particles.removeAll()
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .ccSaffron,
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                size: CGFloat.random(in: 8...16),
                rotation: Double.random(in: 0...360),
                velocity: CGPoint(
                    x: CGFloat.random(in: -100...100),
                    y: CGFloat.random(in: 200...500)
                ),
                rotationSpeed: Double.random(in: -360...360),
                shape: ConfettiShape.allCases.randomElement() ?? .circle
            )
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var color: Color
    var position: CGPoint
    var size: CGFloat
    var rotation: Double
    var velocity: CGPoint
    var rotationSpeed: Double
    var shape: ConfettiShape
}

enum ConfettiShape: CaseIterable {
    case circle
    case square
    case triangle
    case star
}

struct ConfettiParticleView: View {
    let particle: ConfettiParticle

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        particleShape
            .frame(width: particle.size, height: particle.size)
            .rotationEffect(Angle(degrees: rotation))
            .offset(offset)
            .opacity(opacity)
            .position(particle.position)
            .onAppear {
                withAnimation(.easeOut(duration: 2.5)) {
                    offset = CGSize(
                        width: particle.velocity.x,
                        height: particle.velocity.y
                    )
                    rotation = particle.rotation + particle.rotationSpeed
                }
                withAnimation(.easeIn(duration: 2.5).delay(0.5)) {
                    opacity = 0
                }
            }
    }

    @ViewBuilder
    private var particleShape: some View {
        switch particle.shape {
        case .circle:
            Circle().fill(particle.color)
        case .square:
            Rectangle().fill(particle.color)
        case .triangle:
            Triangle().fill(particle.color)
        case .star:
            Star().fill(particle.color)
        }
    }
}

// MARK: - Custom Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let points = 5

        var path = Path()
        for i in 0..<points * 2 {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Celebration Overlay Modifier

struct CelebrationModifier: ViewModifier {
    @Binding var showConfetti: Bool
    var message: String?

    func body(content: Content) -> some View {
        content.overlay {
            ZStack {
                if showConfetti {
                    // Dimmed background
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    // Celebration message
                    if let message = message {
                        VStack(spacing: 16) {
                            Text("🎉")
                                .font(.system(size: 60))
                            Text(message)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Confetti
                    ConfettiView(isActive: $showConfetti)
                }
            }
            .animation(.spring(response: 0.5), value: showConfetti)
        }
    }
}

extension View {
    func celebration(isActive: Binding<Bool>, message: String? = nil) -> some View {
        modifier(CelebrationModifier(showConfetti: isActive, message: message))
    }
}

// MARK: - Badge Earned Animation

struct BadgeEarnedView: View {
    let badge: Badge
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 24) {
                Text("Badge Earned!")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text(badge.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(scale)

                Text(badge.name)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text(badge.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                Button("Awesome!") {
                    isPresented = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.ccSaffron)
                .cornerRadius(25)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .padding(40)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
