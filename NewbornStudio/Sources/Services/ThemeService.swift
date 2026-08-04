import UIKit
import FirebaseFirestore

enum ThemeService {
    /// A small fixed palette so cards look varied without storing a color per style in Firestore.
    private static let tintPalette: [UIColor] = [
        UIColor(hex: 0xEDE7FB), UIColor(hex: 0xE0F3EA), UIColor(hex: 0xFFF3D9),
        UIColor(hex: 0xFCE6EC), UIColor(hex: 0xFFFBF7), UIColor(hex: 0xE0F1E9)
    ]

    static func fetchCategories(completion: @escaping (Result<[ThemeCategory], Error>) -> Void) {
        Firestore.firestore().collection("categories")
            .order(by: "position")
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                let categories = (snapshot?.documents ?? []).map { doc -> ThemeCategory in
                    let data = doc.data()
                    return ThemeCategory(
                        id: doc.documentID,
                        name: data["name"] as? String ?? doc.documentID,
                        position: data["position"] as? Int ?? 0
                    )
                }
                completion(.success(categories))
            }
    }

    /// `categoryId == nil` fetches an unfiltered sample across all categories ("All").
    static func fetchThemes(categoryId: String?, limit: Int = 60, completion: @escaping (Result<[ThemeCard], Error>) -> Void) {
        var query: Query = Firestore.firestore().collection("ai_models")
        if let categoryId {
            query = query.whereField("categoryId", isEqualTo: categoryId)
        }
        query.limit(to: limit).getDocuments { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            let docs = snapshot?.documents ?? []
            let cards = docs.enumerated().map { index, doc -> ThemeCard in
                let data = doc.data()
                let name = data["name"] as? String ?? doc.documentID
                let tint = tintPalette[index % tintPalette.count]
                let previewUrl = (data["previewImageUrl"] as? String).flatMap(URL.init(string:))
                return ThemeCard(id: doc.documentID, name: name, tint: tint, previewImageUrl: previewUrl)
            }
            completion(.success(cards))
        }
    }
}
