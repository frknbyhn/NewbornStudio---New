import Foundation
import FirebaseFirestore
import FirebaseStorage

/// Persists every collage video the user has generated (see MilestoneVideoRenderer) so the
/// "Kolajlarım" gallery (MilestoneCollageGalleryViewController) still has them on a later
/// launch — mirrors MilestoneRemoteStore's schema style, just its own collection since a
/// collage is a very different shape of thing (one video, not a per-milestone capture).
///
/// Schema: `users/{uid}/collages/{collageId}` — {listId, listName, videoUrl, createdAt}.
/// Storage: `users/{uid}/collages/{collageId}.mp4`.
enum MilestoneCollageStore {
    struct SavedCollage: Identifiable {
        let id: String
        let listId: String
        let listName: String
        let videoUrl: URL
        let createdAt: Date
    }

    private static func collagesCollection(_ uid: String) -> CollectionReference {
        Firestore.firestore().collection("users").document(uid).collection("collages")
    }

    static func fetchCollages(completion: @escaping (Result<[SavedCollage], Error>) -> Void) {
        guard let uid = AuthService.currentUserId else {
            completion(.success([]))
            return
        }
        collagesCollection(uid).order(by: "createdAt", descending: true).getDocuments { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            let collages = (snapshot?.documents ?? []).compactMap { doc -> SavedCollage? in
                let data = doc.data()
                guard
                    let listId = data["listId"] as? String,
                    let listName = data["listName"] as? String,
                    let videoUrlString = data["videoUrl"] as? String,
                    let videoUrl = URL(string: videoUrlString),
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                else { return nil }
                return SavedCollage(id: doc.documentID, listId: listId, listName: listName, videoUrl: videoUrl, createdAt: createdAt)
            }
            completion(.success(collages))
        }
    }

    /// Uploads the just-rendered local video file to Storage, then writes its Firestore doc.
    /// Fire-and-forget from the call site (MilestoneListDetailViewController pushes the local
    /// preview immediately and doesn't wait on this) — best-effort, same reasoning as
    /// MilestoneStore's remote writes. Returns the id up front (generated locally, doesn't need
    /// the write to land first) so the caller can pass it straight into MilestoneCollageViewController
    /// for its delete action, without waiting on the upload either.
    @discardableResult
    static func saveCollage(localFileURL: URL, listId: String, listName: String) -> String {
        let collageId = UUID().uuidString
        guard let uid = AuthService.currentUserId else { return collageId }
        let ref = Storage.storage().reference().child("users/\(uid)/collages/\(collageId).mp4")
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        ref.putFile(from: localFileURL, metadata: metadata) { _, error in
            guard error == nil else { return }
            ref.downloadURL { url, error in
                guard let url, error == nil else { return }
                collagesCollection(uid).document(collageId).setData([
                    "listId": listId,
                    "listName": listName,
                    "videoUrl": url.absoluteString,
                    "createdAt": FieldValue.serverTimestamp()
                ])
            }
        }
        return collageId
    }

    /// Deletes both the Firestore doc and the Storage video. Safe to call even if the upload in
    /// saveCollage hasn't finished yet (e.g. the user deletes right after a fresh render) — a
    /// delete on a not-yet-existing doc/object is treated as success either way, nothing left
    /// behind once the in-flight upload does land.
    static func deleteCollage(id: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let uid = AuthService.currentUserId else {
            completion(false)
            return
        }
        let group = DispatchGroup()
        group.enter()
        collagesCollection(uid).document(id).delete { _ in group.leave() }
        group.enter()
        Storage.storage().reference().child("users/\(uid)/collages/\(id).mp4").delete { _ in group.leave() }
        group.notify(queue: .main) { completion(true) }
    }
}
