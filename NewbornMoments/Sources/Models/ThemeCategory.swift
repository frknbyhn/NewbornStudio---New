import Foundation

/// Backed by Firestore `categories` — a small standalone collection (not derived from the
/// 300 `ai_models` docs) since Firestore has no distinct-query support.
struct ThemeCategory {
    let id: String
    let name: String
    let position: Int
    let coverImageUrl: URL?
}
