import UIKit
import FirebaseStorage
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

/// Uploads the user's photo and calls the `generateContent` Cloud Function, which does the
/// actual Wiro submit+poll server-side (so the API secret never ships in the client).
enum GenerationService {
    static func generate(styleId: String, sourceImage: UIImage, completion: @escaping (Result<GenerationResult, Error>) -> Void) {
        guard let uid = AuthService.currentUserId else {
            completion(.failure(GenerationServiceError.notSignedIn))
            return
        }
        guard let data = sourceImage.jpegData(compressionQuality: 0.85) else {
            completion(.failure(GenerationServiceError.invalidImage))
            return
        }

        let path = "users/\(uid)/uploads/\(UUID().uuidString).jpg"
        let ref = Storage.storage().reference(withPath: path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        ref.putData(data, metadata: metadata) { _, error in
            if let error {
                completion(.failure(error))
                return
            }
            callGenerateContent(styleId: styleId, sourceImagePath: path, completion: completion)
        }
    }

    private static func callGenerateContent(styleId: String, sourceImagePath: String, completion: @escaping (Result<GenerationResult, Error>) -> Void) {
        let functions = Functions.functions()
        functions.httpsCallable("generateContent").call(["styleId": styleId, "sourceImagePath": sourceImagePath]) { result, error in
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
                    let styleName = data["styleName"] as? String ?? "Portrait"
                    return Generation(id: doc.documentID, styleName: styleName, resultUrl: resultUrl)
                }
                completion(.success(generations))
            }
    }
}
