import UIKit

/// A minimal in-memory-cached async image loader — no third-party dependency for what's
/// currently just theme thumbnails and generation results.
enum RemoteImageLoader {
    private static let cache = NSCache<NSURL, UIImage>()

    @discardableResult
    static func load(_ url: URL, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        if let cached = cache.object(forKey: url as NSURL) {
            completion(cached)
            return nil
        }
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            cache.setObject(image, forKey: url as NSURL)
            DispatchQueue.main.async { completion(image) }
        }
        task.resume()
        return task
    }
}
