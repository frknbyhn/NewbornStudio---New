import Foundation
import FirebaseFunctions

enum CollageAnimationServiceError: Error {
    case notSignedIn
    case invalidServerResponse
}

struct CollageAnimationStartResult {
    let collageId: String
    let remainingCredits: Int
}

/// Calls `startCollageAnimation` — kicks off a collage-animation job and returns almost
/// immediately with just the new collage's id. The real work (one Wiro video call per item, then
/// concatenation) happens entirely server-side across a chain of background tasks
/// (processCollageAnimationItem -> finalizeCollageAnimation), since it can run far longer than
/// any callable is expected to be held open for. This call itself only needs to survive the
/// validate-charge-credits-write-doc-enqueue-first-task steps, so no extended timeout like
/// AnimationService's is needed here — the server side of THIS call finishes in seconds.
enum CollageAnimationService {
    struct ItemPayload {
        let milestoneId: String?
        let title: String
        let photoUrl: String
        /// Only set for a standard-list milestone (its id doubles as its ai_models style id —
        /// see Milestone.swift) — lets the server build a real per-style animate prompt instead
        /// of falling back to a generic one. nil for custom-list items, which have no catalog
        /// entry to look up.
        let styleId: String?
        /// Burned into this item's own clip as a caption (see finalizeCollageAnimation.js) —
        /// same date the old on-device MilestoneVideoRenderer used to show. Sent as ISO 8601 so
        /// the server can parse it without any timezone/format guessing.
        let capturedAt: Date?
    }

    private static let iso8601Formatter = ISO8601DateFormatter()

    static func start(listId: String, listName: String, items: [ItemPayload], completion: @escaping (Result<CollageAnimationStartResult, Error>) -> Void) {
        guard AuthService.currentUserId != nil else {
            completion(.failure(CollageAnimationServiceError.notSignedIn))
            return
        }
        let payloadItems: [[String: Any]] = items.map { item in
            var dict: [String: Any] = ["title": item.title, "photoUrl": item.photoUrl]
            if let milestoneId = item.milestoneId { dict["milestoneId"] = milestoneId }
            if let styleId = item.styleId { dict["styleId"] = styleId }
            if let capturedAt = item.capturedAt { dict["capturedAt"] = iso8601Formatter.string(from: capturedAt) }
            return dict
        }
        Functions.functions().httpsCallable("startCollageAnimation").call([
            "listId": listId,
            "listName": listName,
            "items": payloadItems
        ]) { result, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard
                let dict = result?.data as? [String: Any],
                let collageId = dict["collageId"] as? String
            else {
                completion(.failure(CollageAnimationServiceError.invalidServerResponse))
                return
            }
            let remainingCredits = (dict["remainingCredits"] as? Int) ?? 0
            completion(.success(CollageAnimationStartResult(collageId: collageId, remainingCredits: remainingCredits)))
        }
    }
}
