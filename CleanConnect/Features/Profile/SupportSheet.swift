import SwiftUI

/// Lets people support a cleaner or drive organiser directly through their own UPI app.
/// CleanConnect never handles the money and takes no cut.
struct SupportSheet: View {
    enum Context { case cleanup, drive(String) }

    let name: String
    let photoURL: String?
    let upiId: String?
    let supportURL: String?
    var context: Context

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var amount: Int? = 51
    @State private var custom = ""
    @State private var apps: [UPI.App] = []
    @State private var showQR = false
    @State private var copied = false

    init(recipient: Profile, context: Context) {
        name = recipient.name
        photoURL = recipient.photoURL
        upiId = recipient.upiId
        supportURL = recipient.supportURL
        self.context = context
    }

    init(name: String, photoURL: String?, upiId: String?, supportURL: String? = nil, context: Context) {
        self.name = name
        self.photoURL = photoURL
        self.upiId = upiId
        self.supportURL = supportURL
        self.context = context
    }

    private let presets = [21, 51, 101, 251, 501]

    private var note: String {
        switch context {
        case .cleanup: String(localized: "Thanks for cleaning")
        case .drive(let title): String(localized: "Supplies: \(title)")
        }
    }

    private var finalAmount: Int? { custom.isEmpty ? amount : Int(custom) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Avatar(url: photoURL, name: name, size: 72)
                        Text("Support \(name)").font(.ccTitle).foregroundStyle(Color.ccInk).multilineTextAlignment(.center)
                        Text(subtitle).font(.cc(.subheadline)).foregroundStyle(Color.ccInk2).multilineTextAlignment(.center)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill").foregroundStyle(Color.ccGreen)
                        Text("100% goes directly to \(name). CleanConnect takes nothing and never sees your payment.")
                            .font(.cc(.footnote, weight: .semibold)).foregroundStyle(Color.ccInk)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.ccMint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    if let upiId {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Amount (optional)").font(.ccHeadline).foregroundStyle(Color.ccInk)
                            FlowLayout(spacing: 8) {
                                ForEach(presets, id: \.self) { value in
                                    Chip(title: "₹\(value)", isSelected: custom.isEmpty && amount == value, tint: .ccSaffron) {
                                        amount = value
                                        custom = ""
                                    }
                                }
                                Chip(title: "Any amount", isSelected: custom.isEmpty && amount == nil, tint: .ccSaffron) {
                                    amount = nil
                                    custom = ""
                                }
                            }
                            TextField("Or type an amount in ₹", text: $custom)
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(Color.ccSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.ccStroke))
                        }

                        VStack(spacing: 10) {
                            ForEach(apps.isEmpty ? [UPI.App.any] : apps) { app in
                                Button {
                                    if let url = UPI.payURL(app: app, upiId: upiId, name: name, amount: finalAmount, note: note) {
                                        openURL(url) { accepted in
                                            if !accepted { showQR = true }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "indianrupeesign.circle.fill")
                                        Text(app == .any ? String(localized: "Pay with any UPI app") : String(localized: "Pay with \(app.name)"))
                                    }
                                }
                                .buttonStyle(.primary(Color(hex: app.color)))
                            }
                        }

                        HStack(spacing: 10) {
                            Button {
                                UIPasteboard.general.string = upiId
                                Haptics.success()
                                copied = true
                            } label: {
                                Label(copied ? "Copied" : upiId, systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .lineLimit(1)
                            }
                            .buttonStyle(.secondary(.ccInk))
                            Button { showQR.toggle() } label: {
                                Label("QR", systemImage: "qrcode")
                            }
                            .buttonStyle(.secondary(.ccInk, fullWidth: false))
                        }

                        if showQR, let qr = UPI.qrCode(upiId: upiId, name: name, amount: finalAmount) {
                            VStack(spacing: 8) {
                                Image(uiImage: qr)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 220, height: 220)
                                    .padding(14)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                Text("Scan with any UPI app").font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    if let supportURL, let url = URL(string: supportURL) {
                        Link(destination: url) {
                            Label("Open \(name)'s support link", systemImage: "link")
                        }
                        .buttonStyle(.secondary(.ccBlue))
                    }

                    Text("Payments happen in your UPI app, directly between you and \(name). It's completely optional and doesn't unlock anything in CleanConnect. Only send money to people you trust.")
                        .font(.cc(.caption)).foregroundStyle(Color.ccInk2).multilineTextAlignment(.center)
                }
                .padding(Metrics.gutter)
                .animation(.snappy, value: showQR)
            }
            .background(Color.ccBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .onAppear { apps = UPI.installedApps().filter { $0 != .any } }
        }
        .presentationDetents([.large])
    }

    private var subtitle: LocalizedStringKey {
        switch context {
        case .cleanup: "Say thanks for cleaning up. Even ₹21 buys gloves and garbage bags for the next cleanup."
        case .drive: "Chip in for gloves, bags and water for this drive."
        }
    }
}
