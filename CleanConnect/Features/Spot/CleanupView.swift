import SwiftUI

/// Post the "after" photo for a spot.
struct CleanupView: View {
    let spot: Spot
    var driveId: String?
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var report = CleanupReport()
    @State private var submitting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Show it sparkling ✨").font(.ccLargeTitle).foregroundStyle(Color.ccInk)
                        Text("Take the after photo from the same angle as the before photo. It makes the slider look amazing.")
                            .font(.cc(.subheadline)).foregroundStyle(Color.ccInk2)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Before").font(.ccHeadline).foregroundStyle(Color.ccInk)
                        RemoteImage(spot.beforePhotos.first)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(alignment: .topLeading) {
                                Text("BEFORE").font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                                    .padding(.horizontal, 9).padding(.vertical, 5).background(Color.ccDirty, in: Capsule()).padding(10)
                            }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("After").font(.ccHeadline).foregroundStyle(Color.ccInk)
                        PhotoStrip(photos: $report.photos, limit: 3, tint: .ccGreen)
                    }

                    VStack(spacing: 12) {
                        stepperRow(icon: "bag.fill", title: "Bags of waste collected", value: $report.bags, range: 0...100, tint: .ccGreen)
                        Divider()
                        stepperRow(icon: "person.2.fill", title: "People who helped", value: $report.crew, range: 1...200, tint: .ccBlue)
                    }
                    .ccCard()

                    TextField("Say something about the cleanup (optional)", text: $report.note, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(14)
                        .background(Color.ccSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.ccStroke))

                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.shield.fill").foregroundStyle(Color.ccSaffron)
                        Text("Stay safe: wear gloves, don't touch sharp objects or medical waste with bare hands, and avoid traffic.")
                            .font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                    }
                    .padding(12)
                    .background(Color.ccSaffronSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(Metrics.gutter)
                .padding(.bottom, 90)
                .readableWidth()
            }
            .background(Color.ccBackground)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Button(action: submit) {
                    if submitting {
                        HStack(spacing: 10) { ProgressView().tint(.white); Text("Uploading…") }
                    } else {
                        Label("Post cleanup  ·  +\(Points.forCleanup(bags: report.bags)) pts", systemImage: "sparkles")
                    }
                }
                .buttonStyle(.primary)
                .disabled(report.photos.isEmpty || submitting)
                .padding(.horizontal, Metrics.gutter)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(submitting) }
            }
        }
        .interactiveDismissDisabled(submitting)
    }

    private func stepperRow(icon: String, title: LocalizedStringKey, value: Binding<Int>, range: ClosedRange<Int>, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(tint).frame(width: 28)
            Text(title).font(.cc(.subheadline, weight: .semibold)).foregroundStyle(Color.ccInk)
            Spacer()
            HStack(spacing: 0) {
                Button { if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1; Haptics.selection() } } label: {
                    Image(systemName: "minus").frame(width: 36, height: 36)
                }
                Text("\(value.wrappedValue)").font(.ccNumber(18)).frame(minWidth: 36).contentTransition(.numericText())
                Button { if value.wrappedValue < range.upperBound { value.wrappedValue += 1; Haptics.selection() } } label: {
                    Image(systemName: "plus").frame(width: 36, height: 36)
                }
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Color.ccInk)
            .background(Color.ccSurface2, in: Capsule())
            .animation(.snappy, value: value.wrappedValue)
        }
    }

    private func submit() {
        guard let profile = session.profile else { session.gate("Sign in to post a cleanup."); return }
        submitting = true
        Task {
            do {
                try await SpotAPI.markCleaned(spot, report: report, by: profile, driveId: driveId)
                dismiss()
                try? await Task.sleep(for: .milliseconds(400))
                session.celebrate("Spot cleaned! You're a Swachh hero.", points: Points.forCleanup(bags: report.bags), icon: "sparkles")
            } catch {
                session.show(error: error)
            }
            submitting = false
        }
    }
}
