import SwiftUI
import AppKit
import UniformTypeIdentifiers

// CleanConnect App Store art: the product page header (5244 x 2950) and the search
// results card (3840 x 2560, 3:2).
//
// iPhone shows only about x 23%-77%, y 0%-63% of the header, and the back/share
// buttons sit over the top corners. So the icon, headline and labels stay inside
// x 30%-70%, y 16%-57%, and the phones sit at the sides for the wider iPad and Mac crops.
//
// Usage (from this folder):
//   swiftc -parse-as-library make_store_art.swift -o /tmp/make_store_art && /tmp/make_store_art .

let paper = Color(red: 0.957, green: 0.965, blue: 0.945)    // #F4F6F1, the app background
let ink = Color(red: 0.059, green: 0.102, blue: 0.078)      // #0F1A14
let green = Color(red: 0.039, green: 0.561, blue: 0.357)    // #0A8F5B
let saffron = Color(red: 0.949, green: 0.478, blue: 0.071)  // #F27A12
let red = Color(red: 0.898, green: 0.282, blue: 0.302)      // #E5484D
let blue = Color(red: 0.184, green: 0.435, blue: 0.922)     // #2F6FEB
let stripColors = [green, saffron, red, blue]

struct Label: Identifiable {
    let id = UUID()
    let text: String
    let color: Color
}

let labels = [
    Label(text: "REPORT SPOTS", color: red),
    Label(text: "BEFORE & AFTER", color: green),
    Label(text: "CLEANUP DRIVES", color: saffron),
    Label(text: "SWACHH POINTS", color: blue),
]

let headline = "Clean up\nIndia."

struct Strip: View {
    let height: CGFloat
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { i in stripColors[i] }
        }
        .frame(height: height)
    }
}

/// Icon, wordmark, headline and labels, centred.
struct Block: View {
    let icon: NSImage
    let scale: CGFloat
    var alignment: HorizontalAlignment = .center

    var body: some View {
        VStack(alignment: alignment, spacing: 70 * scale) {
            HStack(spacing: 34 * scale) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 190 * scale, height: 190 * scale)
                    .clipShape(RoundedRectangle(cornerRadius: 43 * scale, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 14 * scale, y: 6 * scale)
                Text("CleanConnect")
                    .font(.system(size: 132 * scale, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink)
            }
            Text(headline)
                .font(.system(size: 330 * scale, weight: .black, design: .rounded))
                .foregroundStyle(ink)
                .multilineTextAlignment(alignment == .center ? .center : .leading)
                .lineSpacing(-30 * scale)
                .fixedSize()
            HStack(spacing: 22 * scale) {
                ForEach(labels) { label in
                    Text(label.text)
                        .font(.system(size: 50 * scale, weight: .heavy, design: .rounded))
                        .tracking(2 * scale)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28 * scale)
                        .padding(.vertical, 16 * scale)
                        .background(label.color, in: RoundedRectangle(cornerRadius: 18 * scale, style: .continuous))
                }
            }
        }
    }
}

/// A screenshot in an inked phone outline.
struct Phone: View {
    let shot: NSImage
    let width: CGFloat

    var body: some View {
        let h = width * shot.size.height / shot.size.width
        let t = width * 0.028
        let r = width * 0.14
        Image(nsImage: shot)
            .resizable()
            .frame(width: width, height: h)
            .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
            .padding(t)
            .background(RoundedRectangle(cornerRadius: r + t, style: .continuous).fill(ink))
            .shadow(color: .black.opacity(0.18), radius: width * 0.05, y: width * 0.03)
    }
}

struct Header: View {
    let icon: NSImage
    let shots: [String: NSImage]
    let size = CGSize(width: 5244, height: 2950)

    var body: some View {
        ZStack(alignment: .topLeading) {
            paper
            Strip(height: 30)
            // Back phones first, then the front ones over them.
            Phone(shot: shots["04_home"]!, width: 860).rotationEffect(.degrees(-6)).position(x: 380, y: 1720)
            Phone(shot: shots["01_before_after"]!, width: 880).rotationEffect(.degrees(-3)).position(x: 860, y: 1560)
            Phone(shot: shots["05_drive"]!, width: 860).rotationEffect(.degrees(6)).position(x: size.width - 380, y: 1720)
            Phone(shot: shots["03_map"]!, width: 880).rotationEffect(.degrees(3)).position(x: size.width - 860, y: 1560)
            // Centre block: keep within x 30-70%, y 16-57%.
            Block(icon: icon, scale: 0.9)
                .frame(width: size.width)
                .position(x: size.width / 2, y: size.height * 0.365)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

struct SearchCard: View {
    let icon: NSImage
    let shots: [String: NSImage]
    let size = CGSize(width: 3840, height: 2560)

    var body: some View {
        ZStack(alignment: .topLeading) {
            paper
            Strip(height: 22)
            Phone(shot: shots["02_report"]!, width: 760).rotationEffect(.degrees(-7)).position(x: 2420, y: 1360)
            Phone(shot: shots["03_map"]!, width: 760).rotationEffect(.degrees(7)).position(x: 3460, y: 1360)
            Phone(shot: shots["01_before_after"]!, width: 820).position(x: 2940, y: 1290)
            Block(icon: icon, scale: 0.86, alignment: .leading)
                .position(x: 1060, y: size.height / 2)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

@MainActor
func save(_ view: some View, size: CGSize, to url: URL) {
    let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height).environment(\.colorScheme, .light))
    renderer.scale = 1
    renderer.isOpaque = true
    guard let cg = renderer.cgImage else { fatalError("render failed") }
    // Flatten to RGB with no alpha channel, as App Store Connect requires.
    let ctx = CGContext(data: nil, width: cg.width, height: cg.height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(url.lastPathComponent) \(cg.width)x\(cg.height)")
}

@main
struct Main {
    @MainActor static func main() {
        let dir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
        let iconURL = dir.appendingPathComponent("../../CleanConnect/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
        guard let icon = NSImage(contentsOf: iconURL) else { fatalError("missing icon at \(iconURL.path)") }
        var shots = [String: NSImage]()
        for name in ["01_before_after", "02_report", "03_map", "04_home", "05_drive"] {
            guard let img = NSImage(contentsOf: dir.appendingPathComponent("source/\(name).png")) else { fatalError("missing \(name)") }
            shots[name] = img
        }
        save(Header(icon: icon, shots: shots), size: CGSize(width: 5244, height: 2950),
             to: dir.appendingPathComponent("header-5244x2950.png"))
        save(SearchCard(icon: icon, shots: shots), size: CGSize(width: 3840, height: 2560),
             to: dir.appendingPathComponent("search-results-3840x2560.png"))
    }
}
