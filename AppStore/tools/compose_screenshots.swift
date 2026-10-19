import SwiftUI
import AppKit
import UniformTypeIdentifiers

// Composes App Store screenshots: brand background, caption, and the raw simulator
// screenshot in a device-style frame.
// Usage: swiftc -parse-as-library compose_screenshots.swift -o compose && ./compose spec.json

struct Spec: Decodable {
    struct Frame: Decodable {
        let image: String
        let caption: String
        let highlight: String?
        let eyebrow: String?
        let out: String
        let kind: String          // "iphone" | "ipad"
        let style: String?        // "green" | "light" | "saffron"
    }
    let frames: [Frame]
}

extension Color {
    init(_ hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

struct Frame: View {
    let spec: Spec.Frame
    let shot: NSImage
    let size: CGSize

    var isPad: Bool { spec.kind == "ipad" }
    var style: String { spec.style ?? "green" }

    var background: some View {
        ZStack {
            switch style {
            case "light":
                LinearGradient(colors: [Color(0xF4F6F1), Color(0xE3EFE6)], startPoint: .top, endPoint: .bottom)
            case "saffron":
                LinearGradient(colors: [Color(0xFFA640), Color(0xE85D04)], startPoint: .topLeading, endPoint: .bottomTrailing)
            default:
                LinearGradient(colors: [Color(0x13B877), Color(0x07724A), Color(0x033D27)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            Circle().fill(.white.opacity(style == "light" ? 0.0 : 0.07)).frame(width: size.width * 1.1)
                .offset(x: size.width * 0.45, y: -size.height * 0.38)
            Circle().fill(.white.opacity(style == "light" ? 0.0 : 0.05)).frame(width: size.width * 0.9)
                .offset(x: -size.width * 0.5, y: size.height * 0.1)
        }
    }

    var textColor: Color { style == "light" ? Color(0x0F1A14) : .white }
    var accent: Color { style == "light" ? Color(0x0A8F5B) : (style == "saffron" ? Color(0x3D1A00) : Color(0xFFC46B)) }

    var caption: Text {
        guard let h = spec.highlight, let range = spec.caption.range(of: h) else {
            return Text(spec.caption).foregroundColor(textColor)
        }
        let before = String(spec.caption[..<range.lowerBound])
        let after = String(spec.caption[range.upperBound...])
        return Text(before).foregroundColor(textColor) + Text(h).foregroundColor(accent) + Text(after).foregroundColor(textColor)
    }

    var body: some View {
        let w = size.width
        let captionSize: CGFloat = isPad ? 118 : 104
        let deviceWidth: CGFloat = isPad ? w * 0.78 : w * 0.80
        let aspect = shot.size.height / shot.size.width
        let deviceHeight = deviceWidth * aspect
        let corner: CGFloat = isPad ? deviceWidth * 0.035 : deviceWidth * 0.12
        let bezel: CGFloat = isPad ? 22 : 20

        ZStack(alignment: .top) {
            background
            VStack(spacing: isPad ? 34 : 30) {
                if let eyebrow = spec.eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.system(size: isPad ? 40 : 38, weight: .heavy, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(style == "light" ? Color.white : Color(0x0F1A14))
                        .padding(.horizontal, 28).padding(.vertical, 12)
                        .background(Capsule().fill(style == "light" ? Color(0x0A8F5B) : Color.white.opacity(0.92)))
                }
                caption
                    .font(.system(size: captionSize, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(captionSize * 0.02)
                    .minimumScaleFactor(0.6)
                    .lineLimit(3)
                    .frame(maxWidth: w * 0.88)
            }
            .padding(.top, isPad ? 150 : 170)

            Image(nsImage: shot)
                .resizable()
                .frame(width: deviceWidth, height: deviceHeight)
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .padding(bezel)
                .background(RoundedRectangle(cornerRadius: corner + bezel, style: .continuous).fill(Color(0x111111)))
                .overlay(RoundedRectangle(cornerRadius: corner + bezel, style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 3))
                .shadow(color: .black.opacity(0.35), radius: 60, y: 30)
                .offset(y: isPad ? size.height * 0.30 : size.height * 0.285)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

@MainActor
func render(_ frame: Spec.Frame, baseDir: URL) throws {
    let shotURL = URL(fileURLWithPath: frame.image, relativeTo: baseDir)
    guard let shot = NSImage(contentsOf: shotURL) else { throw NSError(domain: "compose", code: 1, userInfo: [NSLocalizedDescriptionKey: "missing \(shotURL.path)"]) }
    let size = frame.kind == "ipad" ? CGSize(width: 2064, height: 2752) : CGSize(width: 1320, height: 2868)
    let renderer = ImageRenderer(content: Frame(spec: frame, shot: shot, size: size).environment(\.colorScheme, .light))
    renderer.scale = 1
    renderer.isOpaque = true
    guard let cg = renderer.cgImage else { throw NSError(domain: "compose", code: 2) }
    let ctx = CGContext(data: nil, width: cg.width, height: cg.height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
    let outURL = URL(fileURLWithPath: frame.out, relativeTo: baseDir)
    try FileManager.default.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(outURL.lastPathComponent) \(cg.width)x\(cg.height)")
}

@main
struct Main {
    @MainActor static func main() throws {
        let specURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let spec = try JSONDecoder().decode(Spec.self, from: Data(contentsOf: specURL))
        for frame in spec.frames { try render(frame, baseDir: specURL.deletingLastPathComponent()) }
    }
}
