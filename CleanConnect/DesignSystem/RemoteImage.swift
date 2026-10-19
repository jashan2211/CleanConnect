import SwiftUI

/// Cached remote image that fills its frame. Shows a soft shimmer while loading.
struct RemoteImage: View {
    let url: String?
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var failed = false

    init(_ url: String?, contentMode: ContentMode = .fill) {
        self.url = url
        self.contentMode = contentMode
        _image = State(initialValue: url.flatMap { ImagePipeline.shared.cached($0) })
    }

    var body: some View {
        Color.ccSurface2
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .transition(.opacity)
                } else if failed || url == nil {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(Color.ccInk2.opacity(0.5))
                } else {
                    ShimmerView()
                }
            }
            .clipped()
            .task(id: url) {
                guard let url else { return }
                if image != nil, ImagePipeline.shared.cached(url) === image { return }
                let loaded = await ImagePipeline.shared.image(for: url)
                withAnimation(.easeOut(duration: 0.2)) {
                    image = loaded
                    failed = loaded == nil
                }
            }
    }
}

struct ShimmerView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, Color.white.opacity(0.35), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.6)
            .offset(x: phase * geo.size.width * 1.6)
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) { phase = 1 }
            }
        }
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}

/// Round avatar with initials fallback on a colour derived from the name.
struct Avatar: View {
    let url: String?
    let name: String
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let url {
                RemoteImage(url)
            } else {
                ZStack {
                    LinearGradient(colors: Avatar.colors(for: name), startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text(initials)
                        .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: size > 50 ? 2 : 1))
        .accessibilityHidden(true)
    }

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init).joined()
        return letters.isEmpty ? "🙂" : letters.uppercased()
    }

    static func colors(for name: String) -> [Color] {
        let palettes: [[Color]] = [
            [Color(hex: 0x10B072), Color(hex: 0x07724A)],
            [Color(hex: 0xFFA640), Color(hex: 0xF0670C)],
            [Color(hex: 0x4F8DF7), Color(hex: 0x2851C7)],
            [Color(hex: 0xB86BF0), Color(hex: 0x7C3AD9)],
            [Color(hex: 0xF56B8D), Color(hex: 0xD02B5B)],
            [Color(hex: 0x22C3D6), Color(hex: 0x0E8A9C)],
        ]
        let hash = name.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7FFF_FFFF }
        return palettes[hash % palettes.count]
    }
}

/// Overlapping avatars, e.g. drive attendees.
struct AvatarStack: View {
    let people: [(url: String?, name: String)]
    var size: CGFloat = 28
    var extra: Int = 0

    var body: some View {
        HStack(spacing: -size * 0.32) {
            ForEach(Array(people.prefix(5).enumerated()), id: \.offset) { _, p in
                Avatar(url: p.url, name: p.name, size: size)
                    .overlay(Circle().strokeBorder(Color.ccSurface, lineWidth: 2))
            }
            if extra > 0 {
                Text("+\(extra)")
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ccInk)
                    .frame(width: size, height: size)
                    .background(Color.ccSurface2, in: Circle())
                    .overlay(Circle().strokeBorder(Color.ccSurface, lineWidth: 2))
            }
        }
    }
}
