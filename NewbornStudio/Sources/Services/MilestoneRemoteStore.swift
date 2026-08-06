import UIKit
import FirebaseFirestore
import FirebaseStorage

/// Persists the Milestones tab so it survives relaunch — backs `MilestoneStore`.
///
/// Schema (fits the rules already reserved for this feature, no rules deploy needed):
/// - `users/{uid}` doc — a `customMilestoneLists` array field: `[{id, name}]`, metadata for
///   every list the user created (the standard lists are hardcoded client-side, never stored).
/// - `users/{uid}/milestones/{milestoneId}` — one doc per captured/added item, covering both
///   standard-list captures (doc id = the hardcoded milestone id, e.g. "age-one-week") and
///   custom-list items (doc id = the milestone's own UUID). `listId` links each doc back to
///   its list either way.
enum MilestoneRemoteStore {
    struct RemoteListMeta {
        let id: String
        let name: String
    }

    struct RemoteMilestoneDoc {
        let id: String
        let listId: String
        let title: String?
        let state: String
        let photoUrl: String?
        let capturedAt: Date?
    }

    private static func userRef(_ uid: String) -> DocumentReference {
        Firestore.firestore().collection("users").document(uid)
    }

    private static func milestonesCollection(_ uid: String) -> CollectionReference {
        userRef(uid).collection("milestones")
    }

    static func fetchAll(completion: @escaping (Result<(lists: [RemoteListMeta], milestones: [RemoteMilestoneDoc]), Error>) -> Void) {
        guard let uid = AuthService.currentUserId else {
            completion(.success((lists: [], milestones: [])))
            return
        }
        let group = DispatchGroup()
        var lists: [RemoteListMeta] = []
        var milestones: [RemoteMilestoneDoc] = []
        var fetchError: Error?

        group.enter()
        userRef(uid).getDocument { snapshot, error in
            if let error { fetchError = error }
            let raw = (snapshot?.data()?["customMilestoneLists"] as? [[String: Any]]) ?? []
            lists = raw.compactMap { dict in
                guard let id = dict["id"] as? String, let name = dict["name"] as? String else { return nil }
                return RemoteListMeta(id: id, name: name)
            }
            group.leave()
        }

        group.enter()
        milestonesCollection(uid).getDocuments { snapshot, error in
            if let error { fetchError = error }
            milestones = (snapshot?.documents ?? []).map { doc in
                let data = doc.data()
                return RemoteMilestoneDoc(
                    id: doc.documentID,
                    listId: data["listId"] as? String ?? "",
                    title: data["title"] as? String,
                    state: data["state"] as? String ?? "pending",
                    photoUrl: data["photoUrl"] as? String,
                    capturedAt: (data["capturedAt"] as? Timestamp)?.dateValue()
                )
            }
            group.leave()
        }

        group.notify(queue: .main) {
            if let fetchError {
                completion(.failure(fetchError))
            } else {
                completion(.success((lists: lists, milestones: milestones)))
            }
        }
    }

    /// Overwrites the whole custom-lists array — small (a handful of lists at most), simpler
    /// and safer than trying to diff it.
    static func saveCustomLists(_ lists: [RemoteListMeta]) {
        guard let uid = AuthService.currentUserId else { return }
        let raw = lists.map { ["id": $0.id, "name": $0.name] }
        userRef(uid).setData(["customMilestoneLists": raw], merge: true)
    }

    /// `capturedAt` should only ever be passed the FIRST time a milestone is captured — see
    /// MilestoneStore.capture, which only fills in a local Date() when the field wasn't already
    /// set, so a later "change photo" never bumps it. Passing nil here just omits the field
    /// from this write rather than clearing an existing one (merge: true).
    static func saveMilestone(id: String, listId: String, title: String?, state: Milestone.State, photoUrl: String?, capturedAt: Date? = nil) {
        guard let uid = AuthService.currentUserId else { return }
        var data: [String: Any] = [
            "listId": listId,
            "state": state == .done ? "done" : "pending",
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let title { data["title"] = title }
        if let photoUrl { data["photoUrl"] = photoUrl }
        if let capturedAt { data["capturedAt"] = Timestamp(date: capturedAt) }
        milestonesCollection(uid).document(id).setData(data, merge: true)
    }

    static func deleteMilestone(id: String) {
        guard let uid = AuthService.currentUserId else { return }
        milestonesCollection(uid).document(id).delete()
    }

    /// Uploads a locally-picked photo (one with no Wiro/Storage URL yet — see MilestoneStore.capture)
    /// so it's durable across relaunches, then calls back with its download URL.
    static func uploadPhoto(_ image: UIImage, milestoneId: String, completion: @escaping (String?) -> Void) {
        guard let uid = AuthService.currentUserId, let data = image.jpegData(compressionQuality: 0.85) else {
            completion(nil)
            return
        }
        let ref = Storage.storage().reference().child("users/\(uid)/milestones/\(milestoneId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        ref.putData(data, metadata: metadata) { _, error in
            if error != nil {
                completion(nil)
                return
            }
            ref.downloadURL { url, _ in
                completion(url?.absoluteString)
            }
        }
    }
}
