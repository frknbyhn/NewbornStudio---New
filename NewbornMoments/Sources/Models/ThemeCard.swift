import UIKit

/// A generation theme shown in the Home gallery grid, backed by Firestore `ai_models`.
struct ThemeCard {
    let id: String
    let name: String
    let tint: UIColor
    let previewImageUrl: URL?
}
