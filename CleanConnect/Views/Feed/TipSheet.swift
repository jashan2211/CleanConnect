// TipSheet.swift
// External-link tipping. The app never moves money — we render a UPI QR
// the user can scan with their banking app, plus a tappable PayPal.me link.

import SwiftUI
import CoreImage.CIFilterBuiltins

struct TipSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let post: Post

    @State private var creator: User?
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let creator, hasAnyPayoutOption(creator) {
                    tipOptionsView(creator: creator)
                } else {
                    EmptyStateView(
                        systemImage: "indianrupeesign.circle",
                        title: "No tip method set up",
                        message: loadError ?? "\(post.userName) hasn't added a UPI ID or PayPal link yet. Drop a comment to say thanks instead."
                    )
                }
            }
            .navigationTitle("Send a tip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .task { await loadCreator() }
        }
    }

    private var loadingView: some View {
        VStack(spacing: AppSpacing.m) {
            ProgressView()
            Text("Loading tip options…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tipOptionsView(creator: User) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.l) {
                creatorHeader(creator: creator)

                if let upiId = creator.upiId, !upiId.isEmpty {
                    upiSection(upiId: upiId, displayName: creator.displayName)
                }

                if let paypalURL = creator.paypalURL,
                   !paypalURL.isEmpty,
                   let url = URL(string: paypalURL) {
                    paypalSection(url: url)
                }

                disclaimer
            }
            .padding(AppSpacing.m)
        }
    }

    private func creatorHeader(creator: User) -> some View {
        VStack(spacing: AppSpacing.s) {
            AsyncImage(url: URL(string: creator.photoURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.ccPrimaryTint)
                    .overlay(
                        Text(String(creator.displayName.prefix(1)).uppercased())
                            .font(.title3.bold())
                            .foregroundColor(.ccPrimary)
                    )
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())

            Text(creator.displayName)
                .font(.headline)

            Text("Tip goes directly to their account")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func upiSection(upiId: String, displayName: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Label("UPI", systemImage: "qrcode")
                .font(.headline)

            if let qr = upiQRCode(payee: upiId, name: displayName) {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220)
                    .padding(AppSpacing.s)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button, style: .continuous))
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("UPI QR code for \(upiId). Scan with any UPI app.")
            }

            HStack {
                Text(upiId)
                    .font(.subheadline.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button {
                    UIPasteboard.general.string = upiId
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline)
                }
                .buttonStyle(GhostActionStyle())
            }

            Button {
                if let url = upiDeepLink(payee: upiId, name: displayName) {
                    openURL(url)
                }
            } label: {
                Label("Open UPI app", systemImage: "arrow.up.forward.app")
            }
            .buttonStyle(PrimaryActionStyle())
        }
        .padding(AppSpacing.m)
        .standardCard(padding: 0)
    }

    private func paypalSection(url: URL) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Label("PayPal", systemImage: "link")
                .font(.headline)

            Text(url.absoluteString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Button {
                openURL(url)
            } label: {
                Label("Open PayPal link", systemImage: "arrow.up.forward.app")
            }
            .buttonStyle(SecondaryActionStyle())
        }
        .padding(AppSpacing.m)
        .standardCard(padding: 0)
    }

    private var disclaimer: some View {
        Text("CleanConnect doesn't process payments. Tips go directly between you and the creator through your banking or PayPal app.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.m)
    }

    // MARK: - Helpers

    private func hasAnyPayoutOption(_ user: User) -> Bool {
        let hasUPI = (user.upiId?.trimmingCharacters(in: .whitespaces).isEmpty == false)
        let hasPayPal = (user.paypalURL?.trimmingCharacters(in: .whitespaces).isEmpty == false)
        return hasUPI || hasPayPal
    }

    private func loadCreator() async {
        // Try the cached current-user first if we happen to be tipping ourselves
        // (preview / dev case). Otherwise fetch.
        do {
            if let fetched = try await UserService.shared.getUser(userId: post.userId) {
                await MainActor.run {
                    creator = fetched
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    loadError = "Couldn't load creator profile."
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                loadError = "Couldn't load creator profile."
                isLoading = false
            }
        }
    }

    private func upiDeepLink(payee: String, name: String) -> URL? {
        var components = URLComponents()
        components.scheme = "upi"
        components.host = "pay"
        components.queryItems = [
            URLQueryItem(name: "pa", value: payee),
            URLQueryItem(name: "pn", value: name),
            URLQueryItem(name: "cu", value: "INR")
        ]
        return components.url
    }

    private func upiQRCode(payee: String, name: String) -> UIImage? {
        guard let url = upiDeepLink(payee: payee, name: name) else { return nil }
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        // Scale up so the QR isn't tiny / blurry.
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
