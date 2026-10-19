import SwiftUI
import PhotosUI
import UIKit

/// Wraps UIImagePickerController for taking a photo with the camera.
struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

/// Grid of picked photos with camera and library buttons. Up to `limit` photos.
struct PhotoStrip: View {
    @Binding var photos: [UIImage]
    var limit = 3
    var tint: Color = .ccGreen
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showCamera = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 104, height: 104)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                withAnimation { _ = photos.remove(at: index) }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black.opacity(0.6))
                            }
                            .padding(5)
                            .accessibilityLabel(Text("Remove photo"))
                        }
                }
                if photos.count < limit {
                    if CameraPicker.isAvailable {
                        addButton(icon: "camera.fill", title: "Camera") { showCamera = true }
                    }
                    PhotosPicker(selection: $pickerItems, maxSelectionCount: limit - photos.count, matching: .images) {
                        addTile(icon: "photo.on.rectangle", title: "Library")
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                if photos.count < limit { photos.append(image) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data), photos.count < limit {
                        photos.append(image.resized(maxDimension: 2000))
                    }
                }
                pickerItems = []
            }
        }
    }

    private func addButton(icon: String, title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) { addTile(icon: icon, title: title) }.buttonStyle(.plain)
    }

    private func addTile(icon: String, title: LocalizedStringKey) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 22, weight: .semibold))
            Text(title).font(.cc(.caption, weight: .semibold))
        }
        .foregroundStyle(tint)
        .frame(width: 104, height: 104)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(tint.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])))
    }
}
