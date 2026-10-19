import SwiftUI

/// Drafts a polite complaint to the local municipal body that people can send via WhatsApp, email or X.
struct ComplaintView: View {
    let spot: Spot?
    var draft: NewSpot?
    @Environment(Session.self) private var session
    @State private var text = ""
    @State private var photo: Image?
    @State private var copied = false

    private var coordinate: CLLocationCoordinate2D? { spot?.coordinate ?? draft?.coordinate }
    private var placeText: String {
        if let spot { return [spot.locality, spot.city, spot.state].filter { !$0.isEmpty }.joined(separator: ", ") }
        if let p = draft?.place { return [p.locality, p.city, p.state].filter { !$0.isEmpty }.joined(separator: ", ") }
        return ""
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.ccBlue)
                        .frame(width: 52, height: 52)
                        .background(Color.ccBlue.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Escalate to the authorities").font(.ccTitle3).foregroundStyle(Color.ccInk)
                        Text("We've drafted a polite complaint. Edit it, then send it to your municipal corporation, ward office or local MLA.")
                            .font(.cc(.footnote)).foregroundStyle(Color.ccInk2)
                    }
                }

                TextEditor(text: $text)
                    .font(.system(.callout))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 320)
                    .padding(12)
                    .background(Color.ccSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.ccStroke))

                VStack(spacing: 10) {
                    if let photo {
                        ShareLink(item: photo, message: Text(text), preview: SharePreview("Complaint", image: photo)) {
                            Label("Send with photo", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.primary(.ccBlue))
                    } else {
                        ShareLink(item: text) {
                            Label("Send", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.primary(.ccBlue))
                    }
                    HStack(spacing: 10) {
                        Button {
                            UIPasteboard.general.string = text
                            Haptics.success()
                            copied = true
                        } label: {
                            Label(copied ? "Copied" : "Copy text", systemImage: copied ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(.secondary(.ccBlue))
                        if let url = URL(string: "mailto:?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                            Link(destination: url) { Label("Email", systemImage: "envelope.fill") }
                                .buttonStyle(.secondary(.ccBlue))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tips that get results").font(.ccHeadline).foregroundStyle(Color.ccInk)
                    tip("Tag your municipal corporation's official account on X with the photo.")
                    tip("File it on your city's grievance portal or the official Swachhata app too.")
                    tip("Ask neighbours to tap “Still dirty” on the spot. More confirmations make a stronger case.")
                }
                .ccCard()
            }
            .padding(Metrics.gutter)
            .readableWidth()
        }
        .background(Color.ccBackground)
        .navigationTitle("Complaint")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if text.isEmpty { text = makeLetter() }
            if let spot, photo == nil, let url = spot.beforePhotos.first, let ui = await ImagePipeline.shared.image(for: url) {
                photo = Image(uiImage: ui)
            } else if let ui = draft?.photos.first {
                photo = Image(uiImage: ui)
            }
        }
    }

    private var subject: String {
        String(localized: "Complaint: garbage needs clearing at \(placeText.isEmpty ? String(localized: "our locality") : placeText)")
    }

    private func tip(_ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.ccGreen)
            Text(text).font(.cc(.subheadline)).foregroundStyle(Color.ccInk2)
        }
    }

    private func makeLetter() -> String {
        let category = spot.map { String(localized: $0.category.resource) } ?? draft.map { String(localized: $0.category.resource) } ?? String(localized: "Garbage dump")
        let since = (spot?.createdAt ?? .now).formatted(date: .long, time: .omitted)
        let confirmations = spot?.stillThereCount ?? 0
        let map = coordinate.map { Directions.mapsLink($0) } ?? ""
        let name = session.profile?.name ?? ""
        var lines = [
            String(localized: "To,\nThe Commissioner / Ward Officer,\nMunicipal Corporation"),
            "",
            String(localized: "Subject: \(subject)"),
            "",
            String(localized: "Respected Sir/Madam,"),
            "",
            String(localized: "I would like to bring to your attention a cleanliness problem in our area that needs urgent action."),
            "",
            String(localized: "• Problem: \(category)"),
            String(localized: "• Location: \(placeText.isEmpty ? "—" : placeText)"),
        ]
        if !map.isEmpty { lines.append(String(localized: "• Map: \(map)")) }
        lines.append(String(localized: "• Reported on: \(since)"))
        if confirmations > 0 {
            lines.append(String(localized: "• \(confirmations) residents have confirmed it is still there."))
        }
        lines += [
            "",
            String(localized: "This is a health hazard for residents and spoils our neighbourhood. I request you to kindly get it cleared at the earliest and arrange regular collection so it doesn't pile up again."),
            "",
            String(localized: "A photo is attached. Thank you for your support in keeping our city clean."),
            "",
            String(localized: "Yours sincerely,"),
            name.isEmpty ? String(localized: "A concerned resident") : name,
            "",
            String(localized: "(Reported via CleanConnect)"),
        ]
        return lines.joined(separator: "\n")
    }
}

import CoreLocation

extension SpotCategory {
    /// Plain-string version of `title` for composing text.
    var resource: String.LocalizationValue {
        switch self {
        case .mixed: "Garbage dump"
        case .plastic: "Plastic litter"
        case .construction: "Construction debris"
        case .drain: "Blocked drain"
        case .burning: "Garbage burning"
        case .water: "River, lake or beach"
        case .walls: "Paan stains & walls"
        case .ewaste: "E-waste"
        case .organic: "Food & organic waste"
        }
    }
}

/// Loads a spot by id, then shows the complaint composer.
struct ComplaintRouteView: View {
    let spotId: String
    @State private var spot: Spot?

    var body: some View {
        Group {
            if let spot { ComplaintView(spot: spot) } else { ProgressView() }
        }
        .task { for await value in SpotAPI.spot(spotId) { spot = value } }
    }
}
