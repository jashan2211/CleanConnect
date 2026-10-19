import Foundation
import CoreLocation
import UIKit

enum Fmt {
    static func distance(from origin: CLLocation?, to target: CLLocation) -> String? {
        guard let origin else { return nil }
        let meters = origin.distance(from: target)
        let measurement: Measurement<UnitLength> = meters < 1000
            ? Measurement(value: (meters / 10).rounded() * 10, unit: .meters)
            : Measurement(value: meters / 1000, unit: .kilometers)
        return measurement.formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                                  numberFormatStyle: .number.precision(.fractionLength(meters < 1000 ? 0 : (meters < 10_000 ? 1 : 0)))))
    }

    static func relative(_ date: Date) -> String {
        let interval = Date.now.timeIntervalSince(date)
        if interval < 60 { return String(localized: "just now") }
        return date.formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
    }

    static func compact(_ n: Int) -> String {
        n.formatted(.number.notation(.compactName))
    }

    static func driveDate(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
    }

    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

extension UIImage {
    /// Downscales so the longest side is at most `maxDimension` points (at scale 1).
    func resized(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return normalizedOrientation() }
        let scale = maxDimension / longest
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func uploadJPEG() -> Data? {
        resized(maxDimension: 1600).jpegData(compressionQuality: 0.72)
    }
}

extension UIApplication {
    var topViewController: UIViewController? {
        let scene = connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
            ?? connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
