import FirebaseFirestore

/// Backed by `users/{uid}/favorites/{styleId}` — existence of the doc means favorited.
enum FavoritesService {
    private static func favoritesCollection(uid: String) -> CollectionReference {
        Firestore.firestore().collection("users").document(uid).collection("favorites")
    }

    static func fetchFavoriteIds(completion: @escaping (Result<Set<String>, Error>) -> Void) {
        guard let uid = AuthService.currentUserId else {
            completion(.success([]))
            return
        }
        favoritesCollection(uid: uid).getDocuments { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            let ids = Set((snapshot?.documents ?? []).map(\.documentID))
            completion(.success(ids))
        }
    }

    /// Fetches the full ThemeCard data for every favorited style — used by Gallery's Favorites tab.
    static func fetchFavoriteThemes(completion: @escaping (Result<[ThemeCard], Error>) -> Void) {
        fetchFavoriteIds { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let ids):
                guard !ids.isEmpty else {
                    completion(.success([]))
                    return
                }
                ThemeService.fetchThemes(byIds: Array(ids), completion: completion)
            }
        }
    }

    static func toggle(styleId: String) {
        guard let uid = AuthService.currentUserId else { return }
        let ref = favoritesCollection(uid: uid).document(styleId)
        ref.getDocument { snapshot, _ in
            if snapshot?.exists == true {
                ref.delete()
            } else {
                ref.setData(["addedAt": FieldValue.serverTimestamp()])
            }
        }
    }
}
