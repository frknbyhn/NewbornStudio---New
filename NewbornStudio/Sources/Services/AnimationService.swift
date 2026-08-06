import Foundation
import FirebaseFunctions

enum AnimationServiceError: Error {
    case notSignedIn
    case invalidServerResponse
}

struct AnimationResult {
    let animationId: String
    let videoUrl: URL
    let remainingCredits: Int
}

/// Calls the `animateResult` Cloud Function — turns an already-generated result portrait into a
/// short video via Wiro's bytedance/seedance-pro-v1-5 (image-to-video). The Wiro submit+poll
/// round-trip happens server-side (API secret never ships in the client), same shape as
/// GenerationService.generate; this just sends a URL (the result image's own durable Storage
/// URL) instead of image bytes, since there's no local file to attach.
enum AnimationService {
    /// Video generation runs far longer than a still-image edit — matches animateResult's own
    /// 540s Cloud Function timeout. The Functions SDK's default (70s) would otherwise fail the
    /// client long before a healthy server call actually finishes.
    private static let callTimeout: TimeInterval = 540

    static func animate(resultUrl: URL, styleId: String, completion: @escaping (Result<AnimationResult, Error>) -> Void) {
        guard AuthService.currentUserId != nil else {
            completion(.failure(AnimationServiceError.notSignedIn))
            return
        }
        let callable = Functions.functions().httpsCallable("animateResult")
        callable.timeoutInterval = callTimeout
        callable.call(["resultUrl": resultUrl.absoluteString, "styleId": styleId]) { result, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard
                let dict = result?.data as? [String: Any],
                let animationId = dict["animationId"] as? String,
                let videoUrlString = dict["videoUrl"] as? String,
                let videoUrl = URL(string: videoUrlString)
            else {
                completion(.failure(AnimationServiceError.invalidServerResponse))
                return
            }
            let remainingCredits = (dict["remainingCredits"] as? Int) ?? 0
            completion(.success(AnimationResult(animationId: animationId, videoUrl: videoUrl, remainingCredits: remainingCredits)))
        }
    }
}
