import UIKit

/// A generation theme shown in the Home gallery grid — backed by Firestore `ai_models` in Phase 6,
/// hardcoded here as sample data until the backend catalog exists.
struct ThemeCard {
    let id: String
    let name: String
    let tint: UIColor

    static let samples: [ThemeCard] = [
        ThemeCard(id: "fairy", name: "Fairy Dream", tint: UIColor(hex: 0xEDE7FB)),
        ThemeCard(id: "astronaut", name: "Astronaut", tint: UIColor(hex: 0xE0F3EA)),
        ThemeCard(id: "tiny_chef", name: "Tiny Chef", tint: UIColor(hex: 0xFFF3D9)),
        ThemeCard(id: "royal", name: "Royal Baby", tint: UIColor(hex: 0xFCE6EC)),
        ThemeCard(id: "safari", name: "Safari", tint: UIColor(hex: 0xE0F3EA)),
        ThemeCard(id: "angel", name: "Little Angel", tint: UIColor(hex: 0xFFFBF7))
    ]
}
