import UIKit

/// Decides which flow the user sees at launch: onboarding (once) → paywall → home.
/// Anonymous-first: no login wall. Real auth/paywall/home wiring lands in later phases;
/// this coordinator is the single place that routing decision changes, so nothing else needs to know.
final class AppCoordinator {
    private let window: UIWindow
    private let defaults = UserDefaults.standard
    private let hasOnboardedKey = "hasCompletedOnboarding"

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        #if DEBUG
        // Screenshot-verification aid only — never reachable in a release build.
        if let debugScreen = ProcessInfo.processInfo.environment["NS_DEBUG_SCREEN"] {
            switch debugScreen {
            case "paywall": window.rootViewController = UIViewController(); showPaywall(); return
            case "home": showHome(); return
            case "coins": window.rootViewController = UINavigationController(rootViewController: CoinPackageViewController()); return
            case "splash": showSplash(); return
            default: break
            }
        }
        #endif
        showSplash()
    }

    private func showSplash() {
        let splash = SplashViewController()
        splash.onFinished = { [weak self] in
            self?.proceedPastSplash()
        }
        window.rootViewController = splash
    }

    private func proceedPastSplash() {
        if defaults.bool(forKey: hasOnboardedKey) {
            showHome()
        } else {
            showOnboarding()
        }
    }

    private func showOnboarding() {
        let onboarding = OnboardingContainerViewController()
        onboarding.onFinished = { [weak self] in
            guard let self else { return }
            self.defaults.set(true, forKey: self.hasOnboardedKey)
            self.showPaywall()
        }
        window.rootViewController = onboarding
    }

    private func showPaywall() {
        let paywall = PaywallViewController()
        paywall.modalPresentationStyle = .fullScreen
        paywall.onDismiss = { [weak self] in
            self?.showHome()
        }
        window.rootViewController?.present(paywall, animated: true)
    }

    private func showHome() {
        let tabBar = MainTabBarController()
        guard window.rootViewController != nil else {
            window.rootViewController = tabBar
            return
        }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            self.window.rootViewController = tabBar
        }
    }
}
