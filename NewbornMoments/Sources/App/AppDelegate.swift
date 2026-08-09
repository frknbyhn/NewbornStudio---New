import UIKit
import FirebaseCore

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Must run before any view controller is built — installs the runtime language
        // override, if the user set one on a previous launch, before the first NSLocalizedString call.
        LanguageManager.bootstrap()
        FirebaseApp.configure()
        // Fired as early as possible (non-blocking) so it has the whole splash screen's 1.6s to
        // resolve before AppCoordinator's post-splash routing decision reads "frun" — see
        // RemoteConfigService's doc comment for what happens if it hasn't resolved by then.
        RemoteConfigService.configure()
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
