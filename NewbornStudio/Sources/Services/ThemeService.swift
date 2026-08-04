import UIKit
import FirebaseFirestore

enum ThemeService {
    /// A small fixed palette so cards look varied without storing a color per style in Firestore.
    private static let tintPalette: [UIColor] = [
        UIColor(hex: 0xEDE7FB), UIColor(hex: 0xE0F3EA), UIColor(hex: 0xFFF3D9),
        UIColor(hex: 0xFCE6EC), UIColor(hex: 0xFFFBF7), UIColor(hex: 0xE0F1E9)
    ]

    static func fetchThemes(limit: Int = 20, completion: @escaping (Result<[ThemeCard], Error>) -> Void) {
        Firestore.firestore().collection("ai_models").limit(to: limit).getDocuments { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            let docs = snapshot?.documents ?? []
            let cards = docs.enumerated().map { index, doc -> ThemeCard in
                let name = doc.data()["name"] as? String ?? doc.documentID
                let tint = tintPalette[index % tintPalette.count]
                return ThemeCard(id: doc.documentID, name: name, tint: tint)
            }
            completion(.success(cards))
        }
    }
}
