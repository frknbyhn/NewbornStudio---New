import UIKit
import CryptoKit

/// Two-tier cache (in-memory NSCache + on-disk in Caches/) for every remote image the app
/// loads — theme thumbnails, category covers, generation results. Firebase Storage URLs don't
/// reliably set cache-control headers we can rely on for free via URLCache, so this caches by
/// content regardless of what the server sends: once fetched, a URL is never re-downloaded
/// across app launches unless the on-disk file is evicted by the OS.
enum RemoteImageLoader {
    private static let memoryCache = NSCache<NSURL, UIImage>()
    private static let ioQueue = DispatchQueue(label: "RemoteImageLoader.io", qos: .utility)

    private static let diskCacheDirectory: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("RemoteImageLoader", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static func diskPath(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let filename = hash.map { String(format: "%02x", $0) }.joined()
        return diskCacheDirectory.appendingPathComponent(filename)
    }

    /// Returns the in-flight URLSessionDataTask so callers can still cancel on cell reuse —
    /// only the network path has anything to cancel; cache hits (memory or disk) resolve the
    /// completion synchronously-ish and return nil, same as before disk caching was added.
    @discardableResult
    static func load(_ url: URL, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        if let cached = memoryCache.object(forKey: url as NSURL) {
            completion(cached)
            return nil
        }

        let path = diskPath(for: url)
        if let data = try? Data(contentsOf: path), let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: url as NSURL)
            completion(image)
            return nil
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            memoryCache.setObject(image, forKey: url as NSURL)
            ioQueue.async { try? data.write(to: path) }
            DispatchQueue.main.async { completion(image) }
        }
        task.resume()
        return task
    }

    /// Seeds the cache with an image the caller already has in memory (e.g. a milestone photo
    /// right after capture, or a Wiro result right after generation) — so the very first
    /// `load(url:)` for that URL hits the cache instead of re-fetching bytes we just uploaded.
    /// The alternative (holding onto the UIImage in whatever long-lived model owns the URL,
    /// forever, "just in case") is what this exists to avoid — see MilestoneStore.capture.
    static func store(_ image: UIImage, for url: URL) {
        memoryCache.setObject(image, forKey: url as NSURL)
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        let path = diskPath(for: url)
        ioQueue.async { try? data.write(to: path) }
    }
}
