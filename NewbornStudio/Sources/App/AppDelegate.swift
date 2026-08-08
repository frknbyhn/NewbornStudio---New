import UIKit
import FirebaseCore

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        // RevenueCat is configured at launch without a uid (Stability Gate rule — don't gate
        // subsystems on auth); identify(uid:) links it to the Firestore uid once sign-in resolves.
        RevenueCatService.configure()
        // Non-blocking — never gate the first frame on network (Stability Gate rule).
        AuthService.ensureSignedIn { result in
            if case .success(let uid) = result {
                RevenueCatService.identify(uid: uid)
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
}
