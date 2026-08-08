import Foundation

/// Mirrors a `users/{uid}/generations/{id}` Firestore document.
struct Generation {
    let id: String
    let styleId: String
    let styleName: String
    let resultUrl: URL
}
