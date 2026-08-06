import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        // RevenueCat is configured at launch without a uid (Stability Gate rule — don't gate
        // subsystems on auth); identify(uid:) links it to the Firestore uid once sign-in resolves.
        RevenueCatService.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        // Non-blocking — never gate the first frame on network (Stability Gate rule).
        AuthService.ensureSignedIn { result in
            if case .success(let uid) = result {
                RevenueCatService.identify(uid: uid)
                // Requested right after sign-in resolves (not before — there's no uid yet to
                // attach a token to) rather than at some more contextual later moment. Harmless
                // if declined; see PushNotificationService's doc comment for why this is also
                // inert either way until an APNs key is uploaded to the Firebase Console.
                PushNotificationService.requestAuthorizationAndRegister()
            }
        }
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("didFailToRegisterForRemoteNotifications: \(error)")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        PushNotificationService.saveToken(fcmToken)
    }

    // Shows the notification banner even while the app is already in the foreground — e.g. the
    // user sitting on My Collages waiting when their video actually finishes.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
