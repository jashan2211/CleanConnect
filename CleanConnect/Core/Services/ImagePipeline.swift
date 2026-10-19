import UIKit

/// Memory + disk cached image loading. Storage download URLs are immutable, so cache hard.
actor ImagePipeline {
    static let shared = ImagePipeline()

    private let memory = NSCache<NSString, UIImage>()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    private let session: URLSession

    init() {
        memory.countLimit = 250
        memory.totalCostLimit = 120 * 1024 * 1024
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 30 * 1024 * 1024, diskCapacity: 400 * 1024 * 1024)
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }

    nonisolated func cached(_ urlString: String) -> UIImage? {
        if let demo = Self.demoImage(urlString) { return demo }
        return memory.object(forKey: urlString as NSString)
    }

    func image(for urlString: String) async -> UIImage? {
        if let hit = cached(urlString) { return hit }
        if let task = inFlight[urlString] { return await task.value }
        let task = Task<UIImage?, Never> { [session] in
            guard let url = URL(string: urlString) else { return nil }
            do {
                let (data, _) = try await session.data(from: url)
                guard let image = UIImage(data: data) else { return nil }
                return image.preparingForDisplay() ?? image
            } catch {
                return nil
            }
        }
        inFlight[urlString] = task
        let image = await task.value
        inFlight[urlString] = nil
        if let image {
            let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
            memory.setObject(image, forKey: urlString as NSString, cost: cost)
        }
        return image
    }

    func store(_ image: UIImage, for urlString: String) {
        memory.setObject(image, forKey: urlString as NSString)
    }

    /// Demo-mode URLs look like `demo:asset_name` and resolve to bundled images.
    nonisolated static func demoImage(_ urlString: String) -> UIImage? {
        guard urlString.hasPrefix("demo:") else { return nil }
        return UIImage(named: String(urlString.dropFirst(5)))
    }
}
