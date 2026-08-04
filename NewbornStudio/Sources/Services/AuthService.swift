import FirebaseAuth

/// Anonymous-first: every launch gets a signed-in Firebase user with no login wall.
/// Sign in with Apple/Google can be linked to this same uid later without losing data.
enum AuthService {
    static func ensureSignedIn(completion: @escaping (Result<String, Error>) -> Void) {
        if let uid = Auth.auth().currentUser?.uid {
            completion(.success(uid))
            return
        }
        Auth.auth().signInAnonymously { result, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let uid = result?.user.uid else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No uid after anonymous sign-in"])))
                return
            }
            completion(.success(uid))
        }
    }

    static var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
}
