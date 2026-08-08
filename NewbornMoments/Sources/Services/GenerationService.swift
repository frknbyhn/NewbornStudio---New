import UIKit
import FirebaseFunctions
import FirebaseFirestore

enum GenerationServiceError: Error {
    case notSignedIn
    case invalidImage
    case invalidServerResponse
}

struct GenerationResult {
    let generationId: String
    let resultUrl: URL
    let remainingCredits: Int
}

/// Calls the `generateContent` Cloud Function, which does the actual Wiro submit+poll
/// server-side (so the API secret never ships in the client). The photo is sent straight
/// through as base64 in the callable payload — Wiro accepts a real multipart file attachment
/// directly (verified empirically), so there's no Storage upload step for the source photo.
enum GenerationService {
    /// `allowPoseChange` only matters when `editInstruction` is set (it's forwarded into
    /// `buildEditPrompt` server-side) — a styleId-only generation already has its prompt
    /// precomputed at seed time from the style's own category flag, nothing to override here.
    /// See PROMPT_TEMPLATE.md's "allowPoseChange" section for why this exists: MilestoneCapture-
    /// ViewController passes true for a curated milestone (First Laugh, Waves Bye-Bye, etc.) —
    /// the whole point of that edit IS a different expression/pose, so the default "preserve
    /// the original expression" instruction can't be allowed to fight it.
    static func generate(styleId: String, sourceImage: UIImage, editInstruction: String? = nil, allowPoseChange: Bool = false, completion: @escaping (Result<GenerationResult, Error>) -> Void) {
        guard AuthService.currentUserId != nil else {
            completion(.failure(GenerationServiceError.notSignedIn))
            return
        }
        guard let data = sourceImage.jpegData(compressionQuality: 0.85) else {
            completion(.failure(GenerationServiceError.invalidImage))
            return
        }

        let imageBase64 = data.base64EncodedString()
        var payload: [String: Any] = ["styleId": styleId, "imageBase64": imageBase64]
        if let editInstruction {
            payload["editInstruction"] = editInstruction
            payload["allowPoseChange"] = allowPoseChange
        }
        Functions.functions().httpsCallable("generateContent").call(payload) { result, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard
                let dict = result?.data as? [String: Any],
                let generationId = dict["generationId"] as? String,
                let resultUrlString = dict["resultUrl"] as? String,
                let resultUrl = URL(string: resultUrlString)
            else {
                completion(.failure(GenerationServiceError.invalidServerResponse))
                return
            }
            let remainingCredits = (dict["remainingCredits"] as? Int) ?? 0
            completion(.success(GenerationResult(generationId: generationId, resultUrl: resultUrl, remainingCredits: remainingCredits)))
        }
    }

    static func fetchGenerations(completion: @escaping (Result<[Generation], Error>) -> Void) {
        guard let uid = AuthService.currentUserId else {
            completion(.failure(GenerationServiceError.notSignedIn))
            return
        }
        Firestore.firestore()
            .collection("users").document(uid).collection("generations")
            .whereField("status", isEqualTo: "complete")
            .order(by: "completedAt", descending: true)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                let generations = (snapshot?.documents ?? []).compactMap { doc -> Generation? in
                    let data = doc.data()
                    guard
                        let resultUrlString = data["resultUrl"] as? String,
                        let resultUrl = URL(string: resultUrlString)
                    else { return nil }
                    let styleName = data["styleName"] as? String ?? NSLocalizedString("Portrait", comment: "Fallback style name when none was recorded")
                    let styleId = data["styleId"] as? String ?? "custom-style"
                    return Generation(id: doc.documentID, styleId: styleId, styleName: styleName, resultUrl: resultUrl)
                }
                completion(.success(generations))
            }
    }
}
