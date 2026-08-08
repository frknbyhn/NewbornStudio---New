import UIKit

/// On-device-only history of photos the user has picked for a generation — lets the Photo
/// Upload screen offer a "reuse a recent photo" shortcut instead of forcing a trip back to the
/// system photo library every time. Deliberately local-only (no Firestore/Storage round trip):
/// this is a convenience shortcut, not durable user data, so it's fine if a fresh install or a
/// new device starts with an empty list.
enum RecentPhotosStore {
    struct Photo: Identifiable {
        let id: String
        let image: UIImage
    }

    private static let maxCount = 10
    private static let idsKey = "recentPhotoIds"
    private static let defaults = UserDefaults.standard

    private static let directory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("RecentPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static func fileURL(for id: String) -> URL {
        directory.appendingPathComponent("\(id).jpg")
    }

    /// Newest first.
    static func recentPhotos() -> [Photo] {
        let ids = defaults.stringArray(forKey: idsKey) ?? []
        return ids.compactMap { id in
            guard let data = try? Data(contentsOf: fileURL(for: id)), let image = UIImage(data: data) else { return nil }
            return Photo(id: id, image: image)
        }
    }

    /// Adds a freshly-picked photo to the front of the list, trimming to `maxCount` (evicting
    /// the oldest file on disk too). Always creates a new entry — re-adding a photo the user
    /// picked from this same list again is handled by `moveToFront`, not this.
    @discardableResult
    static func add(_ image: UIImage) -> Photo {
        let id = UUID().uuidString
        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: fileURL(for: id))
        }
        var ids = defaults.stringArray(forKey: idsKey) ?? []
        ids.insert(id, at: 0)
        while ids.count > maxCount {
            let evicted = ids.removeLast()
            try? FileManager.default.removeItem(at: fileURL(for: evicted))
        }
        defaults.set(ids, forKey: idsKey)
        return Photo(id: id, image: image)
    }

    /// Bumps an existing recent photo back to the front — used when the user re-selects one
    /// from the strip, so it reads as "most recently used" without duplicating the file.
    static func moveToFront(id: String) {
        var ids = defaults.stringArray(forKey: idsKey) ?? []
        guard let index = ids.firstIndex(of: id) else { return }
        ids.remove(at: index)
        ids.insert(id, at: 0)
        defaults.set(ids, forKey: idsKey)
    }

    static func remove(id: String) {
        var ids = defaults.stringArray(forKey: idsKey) ?? []
        ids.removeAll { $0 == id }
        defaults.set(ids, forKey: idsKey)
        try? FileManager.default.removeItem(at: fileURL(for: id))
    }
}
