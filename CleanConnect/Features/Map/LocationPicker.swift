import SwiftUI
import MapKit

/// Full-screen map with a fixed centre pin. Drag the map to place the pin.
struct LocationPicker: View {
    @Binding var coordinate: CLLocationCoordinate2D?
    @Binding var place: Place?
    var title: LocalizedStringKey = "Adjust location"
    @Environment(LocationService.self) private var location
    @Environment(\.dismiss) private var dismiss
    @State private var camera: MapCameraPosition = .automatic
    @State private var center: CLLocationCoordinate2D?
    @State private var preview: Place?
    @State private var dragging = false

    var body: some View {
        NavigationStack {
            Map(position: $camera) {
                UserAnnotation()
            }
            .mapStyle(.standard(pointsOfInterest: .including([.park, .beach, .publicTransport, .school, .hospital])))
            .onMapCameraChange(frequency: .continuous) { _ in dragging = true }
            .onMapCameraChange(frequency: .onEnd) { context in
                dragging = false
                center = context.region.center
            }
            .overlay {
                VStack(spacing: 0) {
                    Image(systemName: "mappin")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(Color.ccDirty, in: Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                    Triangle().fill(.white).frame(width: 14, height: 9).offset(y: -2)
                }
                .offset(y: dragging ? -34 : -26)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: dragging)
                .allowsHitTesting(false)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill").font(.title2).foregroundStyle(Color.ccDirty)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preview?.label.nilIfEmpty ?? String(localized: "Move the map to place the pin"))
                                .font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk)
                            if let city = preview?.cityLabel.nilIfEmpty {
                                Text(city).font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                            }
                        }
                        Spacer()
                    }
                    Button("Use this location") {
                        coordinate = center
                        place = preview
                        dismiss()
                    }
                    .buttonStyle(.primary)
                    .disabled(center == nil)
                }
                .padding(16)
                .background(Color.ccSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .readableWidth(560)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if let c = location.coordinate { withAnimation { camera = .region(.around(c, km: 0.4)) } }
                    } label: { Image(systemName: "location.fill") }
                }
            }
            .task(id: center.map { "\($0.latitude),\($0.longitude)" }) {
                guard let center else { return }
                try? await Task.sleep(for: .milliseconds(250))
                preview = await location.reverseGeocode(center)
            }
            .onAppear {
                let start = coordinate ?? location.coordinate ?? AppConfig.fallbackCoordinate
                camera = .region(.around(start, km: 0.4))
                center = start
                preview = place
            }
        }
    }
}

/// Small non-interactive map preview with a pin.
struct MiniMap: View {
    let coordinate: CLLocationCoordinate2D
    var tint: Color = .ccDirty
    var height: CGFloat = 140

    var body: some View {
        Map(initialPosition: .region(.around(coordinate, km: 0.6)), interactionModes: []) {
            Annotation("", coordinate: coordinate) {
                Circle().fill(tint).frame(width: 22, height: 22)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                    .shadow(radius: 3)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .allowsHitTesting(false)
    }
}

enum Directions {
    static func open(_ coordinate: CLLocationCoordinate2D, name: String) {
        let google = URL(string: "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=walking")
        if let google, UIApplication.shared.canOpenURL(google) {
            UIApplication.shared.open(google)
            return
        }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }

    static func mapsLink(_ coordinate: CLLocationCoordinate2D) -> String {
        "https://maps.google.com/?q=\(String(format: "%.6f", coordinate.latitude)),\(String(format: "%.6f", coordinate.longitude))"
    }
}
