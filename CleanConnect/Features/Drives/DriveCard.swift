import SwiftUI
import CoreLocation

struct DateBlock: View {
    let date: Date
    var compact = false

    var body: some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.month(.abbreviated)).uppercased())
                .font(.system(size: compact ? 10 : 11, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(Color.ccSaffron)
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: compact ? 20 : 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.ccInk)
                .padding(.top, 1)
            Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                .font(.system(size: compact ? 9 : 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ccInk2)
                .padding(.bottom, 4)
        }
        .frame(width: compact ? 48 : 56)
        .background(Color.ccSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
    }
}

/// Drive card with a cover image (used in carousels and lists).
struct DriveCard: View {
    let drive: Drive
    var origin: CLLocation?
    var width: CGFloat? = 280

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Group {
                    if let cover = drive.coverURL {
                        RemoteImage(cover)
                    } else {
                        ZStack {
                            LinearGradient.ccSaffron
                            Image(systemName: "person.3.fill").font(.system(size: 40, weight: .bold)).foregroundStyle(.white.opacity(0.35))
                        }
                    }
                }
                .frame(height: 130)
                .clipped()
                DateBlock(date: drive.startsAt, compact: true).padding(10)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(drive.title).font(.cc(.headline, weight: .bold)).foregroundStyle(Color.ccInk).lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                    Text(Fmt.time(drive.startsAt))
                    Text("·")
                    Image(systemName: "mappin")
                    Text(drive.address.isEmpty ? drive.city : drive.address).lineLimit(1)
                }
                .font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                HStack {
                    Label("\(drive.attendeeCount) going", systemImage: "person.2.fill")
                        .font(.cc(.caption, weight: .bold))
                        .foregroundStyle(Color.ccSaffron)
                    Spacer()
                    if let d = Fmt.distance(from: origin, to: drive.location) {
                        Text(d).font(.cc(.caption, weight: .semibold)).foregroundStyle(Color.ccInk2)
                    }
                }
            }
            .padding(12)
        }
        .frame(width: width)
        .background(Color.ccSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.ccStroke))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}
