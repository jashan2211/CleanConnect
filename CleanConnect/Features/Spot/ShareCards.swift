import SwiftUI

/// Renders shareable 4:5 cards (1080×1350) for WhatsApp, Instagram and friends.
@MainActor
enum ShareCards {
    static let size = CGSize(width: 1080, height: 1350)

    static func reportCard(photo: UIImage, category: SpotCategory, place: String) -> Image? {
        render(ReportCardView(photo: photo, category: category, place: place))
    }

    static func cleanupCard(before: UIImage, after: UIImage, spot: Spot) -> Image? {
        render(CleanupCardView(before: before, after: after, spot: spot))
    }

    static func cleanupCard(for spot: Spot) async -> Image? {
        guard let b = spot.beforePhotos.first, let a = spot.afterPhotos.first,
              let before = await ImagePipeline.shared.image(for: b),
              let after = await ImagePipeline.shared.image(for: a) else { return nil }
        return cleanupCard(before: before, after: after, spot: spot)
    }

    static func reportCard(for spot: Spot) async -> Image? {
        guard let url = spot.beforePhotos.first, let photo = await ImagePipeline.shared.image(for: url) else { return nil }
        return reportCard(photo: photo, category: spot.category, place: spot.placeLabel)
    }

    private static func render(_ view: some View) -> Image? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height).environment(\.colorScheme, .light))
        renderer.scale = 1
        guard let ui = renderer.uiImage else { return nil }
        return Image(uiImage: ui)
    }
}

private struct BrandFooter: View {
    var body: some View {
        HStack(spacing: 18) {
            Image("BrandMark").resizable().frame(width: 76, height: 76)
            VStack(alignment: .leading, spacing: 2) {
                Text("CleanConnect").font(.system(size: 40, weight: .heavy, design: .rounded))
                Text("Clean India, together").font(.system(size: 28, weight: .semibold, design: .rounded)).opacity(0.7)
            }
            Spacer()
            Text("Free on the\nApp Store")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.trailing)
                .opacity(0.75)
        }
        .foregroundStyle(Color(hex: 0x0F1A14))
    }
}

private struct ReportCardView: View {
    let photo: UIImage
    let category: SpotCategory
    let place: String

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: 1080, height: 930)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text("NEEDS CLEANING")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28).padding(.vertical, 16)
                        .background(Color(hex: 0xE5484D), in: Capsule())
                        .padding(44)
                }
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    Image(systemName: category.icon).font(.system(size: 44, weight: .bold)).foregroundStyle(category.tint)
                    Text(category.title).font(.system(size: 56, weight: .heavy, design: .rounded))
                }
                if !place.isEmpty {
                    Label(place, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .opacity(0.75)
                        .lineLimit(1)
                }
                Text("Can you help clean it? Find it on the CleanConnect map.")
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .opacity(0.7)
                Spacer(minLength: 0)
                BrandFooter()
            }
            .foregroundStyle(Color(hex: 0x0F1A14))
            .padding(48)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white)
        }
        .frame(width: 1080, height: 1350)
    }
}

private struct CleanupCardView: View {
    let before: UIImage
    let after: UIImage
    let spot: Spot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Before → After")
                    .font(.system(size: 54, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "sparkles").font(.system(size: 50, weight: .bold)).foregroundStyle(Color(hex: 0xFFD23F))
            }
            .padding(.horizontal, 48)
            .frame(height: 150)

            HStack(spacing: 12) {
                photo(before, label: "BEFORE", color: Color(hex: 0xE5484D))
                photo(after, label: "AFTER", color: Color(hex: 0x12A365))
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 14) {
                Text("Cleaned by \(spot.cleanedByName ?? spot.reporterName)")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                HStack(spacing: 28) {
                    Label("\(spot.bags) bags", systemImage: "bag.fill")
                    Label("\(spot.crew)", systemImage: "person.2.fill")
                    Label(spot.placeLabel, systemImage: "mappin").lineLimit(1)
                }
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .opacity(0.8)
                Spacer(minLength: 0)
                BrandFooter()
            }
            .foregroundStyle(Color(hex: 0x0F1A14))
            .padding(44)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white, in: UnevenRoundedRectangle(topLeadingRadius: 48, topTrailingRadius: 48))
            .padding(.top, 24)
        }
        .frame(width: 1080, height: 1350)
        .background(LinearGradient.ccHero)
    }

    private func photo(_ image: UIImage, label: LocalizedStringKey, color: Color) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 510, height: 720)
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .overlay(alignment: .topLeading) {
                Text(label)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(color, in: Capsule())
                    .padding(24)
            }
    }
}
