import UIKit
import UserNotifications
import FirebaseFirestore

/// Registers this device for push notifications and keeps its FCM token saved on the signed-in
/// user's Firestore doc (`users/{uid}.fcmTokens`) — that's what the collage-animation background
/// pipeline (functions/helpers/collageNotify.js, sent from finalizeCollageAnimation once a
/// collage is ready) sends the "your collage is ready" push to.
///
/// Requires an APNs Auth Key uploaded to the Firebase Console — not something this code can set
/// up itself. Everything here is a harmless no-op without it: permission requests still work
/// (they're an OS-level prompt, not Firebase-specific), but no token will ever successfully
/// register with FCM, so saveToken(_:) simply never gets called and My Collages' in-app
/// "Preparing…" status (plus its own foreground poll) remains the only way to know a collage
/// finished — the flow works, it just isn't backed by a real push yet until that key exists.
enum PushNotificationService {
    static func requestAuthorizationAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("Notification authorization request failed: \(error)")
            }
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    /// Called from AppDelegate once Firebase Messaging hands back a fresh FCM token — saves it
    /// onto the signed-in user's doc so a server-side send can reach this device. Uses
    /// arrayUnion (not overwrite) since the same account can be signed in on more than one
    /// device/reinstall, each with its own token.
    static func saveToken(_ token: String) {
        guard let uid = AuthService.currentUserId else { return }
        Firestore.firestore().collection("users").document(uid).setData(
            ["fcmTokens": FieldValue.arrayUnion([token])], merge: true
        )
    }
}
