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
        if defaults.bool(forKey: hasOnboardedKey) {
            showHome()
        } else {
            showOnboarding()
        }
    }

    private func showOnboarding() {
        let onboarding = OnboardingContainerViewController()
        onboarding.onFinished = { [weak self] in
            self?.defaults.set(true, forKey: self?.hasOnboardedKey ?? "hasCompletedOnboarding")
            self?.showHome()
        }
        window.rootViewController = onboarding
    }

    private func showHome() {
        // Placeholder until Phase 5 finishes the real home/tab flow.
        window.rootViewController = RootViewController()
    }
}
