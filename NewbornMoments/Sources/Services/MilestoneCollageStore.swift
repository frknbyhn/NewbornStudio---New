import Foundation
import FirebaseFirestore
import FirebaseStorage

/// Reads the "My Collages" gallery (MilestoneCollageGalleryViewController) list — creation
/// itself now goes entirely through CollageAnimationService/startCollageAnimation (a server-side
/// job chain: one Wiro animate call per item, then concatenation), not through this file; it
/// used to also own the client-side upload for the old on-device Ken Burns renderer, which this
/// feature fully replaced.
///
/// Schema: `users/{uid}/collages/{collageId}` —
/// `{listId, listName, status: "generating"|"complete"|"failed", itemCount, videoUrl?, createdAt}`.
/// Storage (once complete): `users/{uid}/collages/{collageId}.mp4`.
enum MilestoneCollageStore {
    enum Status: String {
        case generating
        case complete
        case failed
    }

    /// Separate from `Status` — set by startCollageMusic/renderCollageMusic once a collage's own
    /// video is already `.complete`, so "adding background music" never hides or invalidates the
    /// already-playable video while it runs. nil/absent means music was never requested for this
    /// collage.
    enum MusicStatus: String {
        case generating
        case complete
        case failed
    }

    struct SavedCollage: Identifiable {
        let id: String
        let listId: String
        let listName: String
        let status: Status
        let itemCount: Int
        /// nil while `status == .generating` (or `.failed`) — only ever set once the background
        /// job's finalize step actually writes it. Also updated in place (new download token) by
        /// renderCollageMusic once a music track is muxed in, so this always points at the video
        /// that's actually meant to play right now.
        let videoUrl: URL?
        let musicStatus: MusicStatus?
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
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                else { return nil }
                // Docs written before this status field existed (the old on-device renderer)
                // have no status at all — treat those as complete, matching their old behavior.
                let status = Status(rawValue: data["status"] as? String ?? "complete") ?? .complete
                let itemCount = data["itemCount"] as? Int ?? 0
                let videoUrl = (data["videoUrl"] as? String).flatMap(URL.init(string:))
                let musicStatus = (data["musicStatus"] as? String).flatMap(MusicStatus.init(rawValue:))
                return SavedCollage(id: doc.documentID, listId: listId, listName: listName, status: status, itemCount: itemCount, videoUrl: videoUrl, musicStatus: musicStatus, createdAt: createdAt)
            }
            completion(.success(collages))
        }
    }

    /// Deletes the Firestore doc and (if it exists yet) the final Storage video. Safe to call on
    /// a still-`.generating` collage — the background job chain checks `status` before each step
    /// and treats a missing doc as "nothing to do", so it won't resurrect anything after this.
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
