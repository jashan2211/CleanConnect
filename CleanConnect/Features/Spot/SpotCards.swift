import SwiftUI
import CoreLocation

/// Compact card for the "near you" carousels.
struct SpotTile: View {
    let spot: Spot
    var origin: CLLocation?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RemoteImage(spot.coverPhoto)
                .frame(height: 132)
                .overlay(alignment: .topLeading) {
                    StatusBadge(status: spot.status, compact: true).padding(10)
                }
                .overlay(alignment: .bottomTrailing) {
                    if let distance = Fmt.distance(from: origin, to: spot.location) {
                        Label(distance, systemImage: "location.fill")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.black.opacity(0.55), in: Capsule())
                            .padding(8)
                    }
                }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: spot.category.icon).font(.caption.weight(.bold)).foregroundStyle(spot.category.tint)
                    Text(spot.category.title).font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk).lineLimit(1)
                }
                Text(spot.placeLabel).font(.cc(.caption)).foregroundStyle(Color.ccInk2).lineLimit(1)
                if spot.stillThereCount > 0, spot.status != .cleaned {
                    Label("\(spot.stillThereCount) confirmed", systemImage: "eye.fill")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.ccDirty)
                        .padding(.top, 2)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 200)
        .background(Color.ccSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.ccStroke))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

/// Big before/after card for the cleanup feed.
struct CleanupCard: View {
    let spot: Spot
    var onRespect: (() -> Void)?
    var hasRespected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                NavigationLink(value: Route.profile(spot.cleanedBy ?? spot.reporterId)) {
                    Avatar(url: spot.cleanedByPhoto, name: spot.cleanedByName ?? spot.reporterName, size: 40)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(spot.cleanedByName ?? spot.reporterName)
                        .font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin").font(.caption2)
                        Text(spot.placeLabel)
                        Text("·")
                        Text(Fmt.relative(spot.cleanedAt ?? spot.createdAt))
                    }
                    .font(.cc(.caption)).foregroundStyle(Color.ccInk2).lineLimit(1)
                }
                Spacer()
                StatusBadge(status: .cleaned, compact: true)
            }

            if spot.afterPhotos.isEmpty {
                RemoteImage(spot.beforePhotos.first).frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                BeforeAfterSlider(before: spot.beforePhotos.first, after: spot.afterPhotos.first, cornerRadius: 18)
                    .frame(height: 280)
            }

            if let note = spot.cleanupNote {
                Text(note).font(.cc(.subheadline)).foregroundStyle(Color.ccInk).lineLimit(3)
            }

            HStack(spacing: 14) {
                Label("\(spot.bags) bags", systemImage: "bag.fill")
                Label("\(spot.crew) \(spot.crew == 1 ? String(localized: "person") : String(localized: "people"))", systemImage: "person.2.fill")
                if spot.verifiedCount > 0 {
                    Label("\(spot.verifiedCount)", systemImage: "checkmark.seal.fill").foregroundStyle(Color.ccGreen)
                }
                Spacer()
                if let onRespect {
                    Button {
                        Haptics.tap()
                        onRespect()
                    } label: {
                        HStack(spacing: 5) {
                            Text("🙏")
                            Text("\(spot.respectCount)").font(.ccNumber(14))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(hasRespected ? Color.ccSaffronSoft : Color.ccSurface2, in: Capsule())
                        .overlay(Capsule().strokeBorder(hasRespected ? Color.ccSaffron : .clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Respect, \(spot.respectCount)"))
                }
            }
            .font(.cc(.caption, weight: .semibold))
            .foregroundStyle(Color.ccInk2)
        }
        .ccCard(padding: 14)
    }
}

/// Row used in lists (profile tabs, map list).
struct SpotRow: View {
    let spot: Spot
    var origin: CLLocation?

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(spot.coverPhoto)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(spot.category.title).font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk).lineLimit(1)
                    Spacer(minLength: 4)
                    StatusBadge(status: spot.status, compact: true)
                }
                Text(spot.placeLabel).font(.cc(.caption)).foregroundStyle(Color.ccInk2).lineLimit(1)
                HStack(spacing: 8) {
                    Text(Fmt.relative(spot.createdAt))
                    if let d = Fmt.distance(from: origin, to: spot.location) {
                        Text("·")
                        Text(d)
                    }
                }
                .font(.cc(.caption2)).foregroundStyle(Color.ccInk2)
            }
        }
        .padding(10)
        .background(Color.ccSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.ccStroke))
    }
}
