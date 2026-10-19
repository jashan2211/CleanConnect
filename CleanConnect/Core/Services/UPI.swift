import UIKit
import CoreImage.CIFilterBuiltins

/// UPI deep links. Money moves between the two people's UPI apps; CleanConnect never touches it.
enum UPI {
    static func isValid(_ text: String) -> Bool {
        let t = text.trimmed
        return t.range(of: #"^[A-Za-z0-9.\-_]{2,256}@[A-Za-z][A-Za-z0-9]{1,63}$"#, options: .regularExpression) != nil
    }

    enum App: String, CaseIterable, Identifiable {
        case gpay, phonepe, paytm, bhim, any

        var id: String { rawValue }

        var name: String {
            switch self {
            case .gpay: "Google Pay"
            case .phonepe: "PhonePe"
            case .paytm: "Paytm"
            case .bhim: "BHIM"
            case .any: String(localized: "Other UPI app")
            }
        }

        var color: UInt32 {
            switch self {
            case .gpay: 0x1A73E8
            case .phonepe: 0x5F259F
            case .paytm: 0x00BAF2
            case .bhim: 0xF47920
            case .any: 0x0A8F5B
            }
        }

        /// Base for the pay intent. All accept the standard UPI query parameters.
        var base: String {
            switch self {
            case .gpay: "gpay://upi/pay"
            case .phonepe: "phonepe://pay"
            case .paytm: "paytmmp://pay"
            case .bhim: "bhim://upi/pay"
            case .any: "upi://pay"
            }
        }
    }

    static func payURL(app: App, upiId: String, name: String, amount: Int?, note: String) -> URL? {
        var comps = URLComponents(string: app.base)
        var items = [
            URLQueryItem(name: "pa", value: upiId.trimmed),
            URLQueryItem(name: "pn", value: String(name.prefix(40))),
            URLQueryItem(name: "tn", value: String(note.prefix(60))),
            URLQueryItem(name: "cu", value: "INR"),
        ]
        if let amount, amount > 0 { items.append(URLQueryItem(name: "am", value: "\(amount).00")) }
        comps?.queryItems = items
        return comps?.url
    }

    @MainActor
    static func installedApps() -> [App] {
        App.allCases.filter { app in
            guard let url = URL(string: app.base) else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }

    /// QR any UPI app can scan (useful when paying from a second phone).
    static func qrCode(upiId: String, name: String, amount: Int?) -> UIImage? {
        guard let url = payURL(app: .any, upiId: upiId, name: name, amount: amount, note: "CleanConnect") else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cg = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
