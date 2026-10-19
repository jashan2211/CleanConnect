import SwiftUI

struct StatusBadge: View {
    let status: SpotStatus
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon).font(.system(size: compact ? 9 : 11, weight: .bold))
            Text(compact ? status.shortTitle : status.title)
                .font(.system(size: compact ? 11 : 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(status.color, in: Capsule())
    }
}

struct CategoryLabel: View {
    let category: SpotCategory

    var body: some View {
        Label {
            Text(category.title)
        } icon: {
            Image(systemName: category.icon).foregroundStyle(category.tint)
        }
        .font(.cc(.subheadline, weight: .semibold))
        .foregroundStyle(Color.ccInk)
    }
}

struct SectionHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.ccTitle3).foregroundStyle(Color.ccInk)
                if let subtitle {
                    Text(subtitle).font(.cc(.footnote)).foregroundStyle(Color.ccInk2)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.ccMint).frame(width: 76, height: 76)
                Image(systemName: icon).font(.system(size: 30, weight: .semibold)).foregroundStyle(Color.ccGreen)
            }
            Text(title).font(.ccHeadline).foregroundStyle(Color.ccInk).multilineTextAlignment(.center)
            Text(message).font(.cc(.subheadline)).foregroundStyle(Color.ccInk2).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.secondary(.ccGreen, fullWidth: false))
                    .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

/// Small metric: big number over a caption.
struct StatTile: View {
    let value: String
    let label: LocalizedStringKey
    var icon: String?
    var tint: Color = .ccGreen

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let icon {
                Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(tint)
                    .frame(width: 28, height: 28).background(tint.opacity(0.12), in: Circle())
            }
            Text(value).font(.ccNumber(24)).foregroundStyle(Color.ccInk).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.ccCaption).foregroundStyle(Color.ccInk2).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ccCard(padding: 14, corner: 18)
    }
}

/// Points capsule with optional streak flame.
struct PointsPill: View {
    let points: Int
    var streak: Int = 0

    var body: some View {
        HStack(spacing: 8) {
            if streak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill").foregroundStyle(Color.ccSaffron)
                    Text("\(streak)").font(.ccNumber(15))
                }
            }
            HStack(spacing: 3) {
                Image(systemName: "leaf.fill").foregroundStyle(Color.ccGreen)
                Text(points.formatted()).font(.ccNumber(15))
            }
        }
        .foregroundStyle(Color.ccInk)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.ccSurface, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.ccStroke))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(points) Swachh Points, \(streak) day streak"))
    }
}

struct LevelRing: View {
    let progress: Double
    let level: Level
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle().stroke(level.color.opacity(0.15), lineWidth: size * 0.1)
            Circle()
                .trim(from: 0, to: max(progress, 0.02))
                .stroke(level.color, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: level.icon)
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundStyle(level.color)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Before / After

/// Drag the handle to wipe between the before and after photos.
struct BeforeAfterSlider: View {
    let before: String?
    let after: String?
    var cornerRadius: CGFloat = Metrics.corner
    var showsLabels = true
    @State private var position: CGFloat = 0.5
    @State private var hinted = false

    var body: some View {
        GeometryReader { geo in
            let x = geo.size.width * position
            ZStack(alignment: .leading) {
                RemoteImage(after)
                    .frame(width: geo.size.width, height: geo.size.height)
                RemoteImage(before)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .mask(alignment: .leading) { Rectangle().frame(width: x) }
                if showsLabels {
                    HStack {
                        tag("BEFORE", color: .ccDirty).opacity(position > 0.15 ? 1 : 0)
                        Spacer()
                        tag("AFTER", color: .ccCleaned).opacity(position < 0.85 ? 1 : 0)
                    }
                    .padding(12)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                handle(height: geo.size.height).offset(x: x - 22)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        position = min(max(value.location.x / geo.size.width, 0.02), 0.98)
                    }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onAppear {
            guard !hinted else { return }
            hinted = true
            withAnimation(.easeInOut(duration: 0.7).delay(0.4)) { position = 0.32 }
            withAnimation(.easeInOut(duration: 0.8).delay(1.1)) { position = 0.5 }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Before and after photos"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: position = min(position + 0.1, 0.98)
            case .decrement: position = max(position - 0.1, 0.02)
            @unknown default: break
            }
        }
    }

    private func tag(_ text: LocalizedStringKey, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(.white)
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(color, in: Capsule())
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }

    private func handle(height: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(.white).frame(width: 3, height: height).shadow(color: .black.opacity(0.3), radius: 3)
            Circle().fill(.white).frame(width: 44, height: 44).shadow(color: .black.opacity(0.25), radius: 6, y: 2)
            Image(systemName: "arrow.left.and.right").font(.system(size: 16, weight: .bold)).foregroundStyle(Color.ccGreenDeep)
        }
        .frame(width: 44)
    }
}

// MARK: - Celebration

struct ConfettiView: View {
    struct Piece {
        let x: CGFloat, delay: Double, speed: CGFloat, spin: Double, size: CGFloat, color: Color, drift: CGFloat
    }

    private let pieces: [Piece] = (0..<70).map { _ in
        Piece(x: .random(in: 0...1), delay: .random(in: 0...0.4), speed: .random(in: 0.55...1.1),
              spin: .random(in: 180...720), size: .random(in: 6...11),
              color: [Color.ccGreen, .ccSaffron, .ccBlue, Color(hex: 0xFFD23F), .ccDirty, .white].randomElement()!,
              drift: .random(in: -40...40))
    }
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSince(start)
                for piece in pieces {
                    let local = max(t - piece.delay, 0)
                    let y = -20 + CGFloat(local) * size.height * piece.speed
                    guard y < size.height + 20 else { continue }
                    let x = piece.x * size.width + sin(CGFloat(local) * 3) * piece.drift
                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .degrees(piece.spin * local))
                    ctx.fill(Path(roundedRect: CGRect(x: -piece.size / 2, y: -piece.size / 4, width: piece.size, height: piece.size / 2),
                                  cornerRadius: 1.5), with: .color(piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { start = .now }
    }
}

/// Full-screen overlay after earning points.
struct CelebrationOverlay: View {
    let celebration: Celebration
    var onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.45 : 0).ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
            ConfettiView().ignoresSafeArea()
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(LinearGradient.ccHero).frame(width: 96, height: 96)
                    Image(systemName: celebration.icon).font(.system(size: 42, weight: .bold)).foregroundStyle(.white)
                }
                .scaleEffect(appeared ? 1 : 0.4)
                Text(celebration.title).font(.ccTitle).foregroundStyle(Color.ccInk).multilineTextAlignment(.center)
                if celebration.points > 0 {
                    Text("+\(celebration.points) Swachh Points")
                        .font(.ccNumber(20))
                        .foregroundStyle(Color.ccGreen)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.ccMint, in: Capsule())
                }
                Button("Awesome!", action: onDismiss)
                    .buttonStyle(.primary)
                    .padding(.top, 6)
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background(Color.ccSurface, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 30, y: 10)
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { appeared = true }
        }
    }
}

struct ToastView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.icon).foregroundStyle(toast.isError ? Color.ccDirty : Color.ccGreen)
            Text(toast.message).font(.cc(.subheadline, weight: .semibold)).foregroundStyle(Color.ccInk)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .ccGlass(in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .padding(.horizontal, 20)
    }
}

/// Flow layout for chips that wrap onto multiple lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(maxX, width), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
