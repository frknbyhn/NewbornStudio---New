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
            case "coins":
                window.rootViewController = CoinPackageViewController.presented()
                return
            case "splash": showSplash(); return
            case "result":
                let tab = MainTabBarController()
                tab.loadViewIfNeeded()
                window.rootViewController = tab
                tab.selectedIndex = 2
                let theme = ThemeCard(id: "demo", name: "Demo Theme", tint: UIColor(hex: 0xEBC3CC), previewImageUrl: nil)
                let resultUrl = URL(string: "https://picsum.photos/seed/newborn/900/1300")!
                let result = ResultViewController(theme: theme, sourceImage: nil, resultUrl: resultUrl)
                (tab.viewControllers?[2] as? UINavigationController)?.pushViewController(result, animated: false)
                return
            case "milestones-list":
                MilestoneStore.shared.debugSeedCapturedMilestones(photoUrls: Self.debugMarketingPhotoUrls)
                let tab = MainTabBarController()
                tab.loadViewIfNeeded()
                window.rootViewController = tab
                tab.selectedIndex = 1
                return
            case "milestone-detail":
                MilestoneStore.shared.debugSeedCapturedMilestones(photoUrls: Self.debugMarketingPhotoUrls)
                let detail = MilestoneListDetailViewController(list: MilestoneStore.shared.lists[0])
                window.rootViewController = UINavigationController(rootViewController: detail)
                return
            case "photo-upload":
                // Screenshot-verification aid only — seeds a couple of recent photos so the
                // "Recently Used" strip actually has content to look at.
                if RecentPhotosStore.recentPhotos().isEmpty, let seed = UIImage(systemName: "photo.fill") {
                    RecentPhotosStore.add(seed)
                    RecentPhotosStore.add(seed)
                }
                let theme = ThemeCard(id: "demo", name: "Demo Theme", tint: UIColor(hex: 0xEBC3CC), previewImageUrl: nil)
                let upload = PhotoUploadViewController(theme: theme)
                window.rootViewController = UINavigationController(rootViewController: upload)
                return
            case "creditgate":
                let root = UIViewController()
                root.view.backgroundColor = .white
                window.rootViewController = UINavigationController(rootViewController: root)
                CreditsService.requireCredits(presentingFrom: root) {
                    let label = UILabel()
                    label.text = "ALLOWED"
                    label.font = .boldSystemFont(ofSize: 32)
                    label.translatesAutoresizingMaskIntoConstraints = false
                    root.view.addSubview(label)
                    NSLayoutConstraint.activate([
                        label.centerXAnchor.constraint(equalTo: root.view.centerXAnchor),
                        label.centerYAnchor.constraint(equalTo: root.view.centerYAnchor)
                    ])
                }
                return
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
        let paywall = PaywallViewController.presented()
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

    #if DEBUG
    /// Screenshot-verification aid only — marketing-set portraits uploaded to Storage for the
    /// milestones-list/milestone-detail debug screens above. Remove once the marketing
    /// screenshots are final.
    private static let debugMarketingPhotoUrls: [String] = [
        "https://firebasestorage.googleapis.com/v0/b/newborn-moments.firebasestorage.app/o/marketing-screenshots%2Fmosaic_astronaut.png?alt=media&token=b8732d3c-182c-423d-bbd9-44b5bfbe6255",
        "https://firebasestorage.googleapis.com/v0/b/newborn-moments.firebasestorage.app/o/marketing-screenshots%2Fmosaic_firefighter.png?alt=media&token=4f4eef19-2d85-4883-9ec3-65543d012c68",
        "https://firebasestorage.googleapis.com/v0/b/newborn-moments.firebasestorage.app/o/marketing-screenshots%2Fhero_wizard.png?alt=media&token=a096b2bf-8dac-49e1-b26b-917696dc2259",
        "https://firebasestorage.googleapis.com/v0/b/newborn-moments.firebasestorage.app/o/marketing-screenshots%2Fmosaic_lion_cub.png?alt=media&token=4258b7be-4107-45fa-be7c-a5ab49d5f90e",
        "https://firebasestorage.googleapis.com/v0/b/newborn-moments.firebasestorage.app/o/marketing-screenshots%2Fmosaic_bubble_diver.png?alt=media&token=84e7f489-be3d-4213-b246-c49587a64e49",
        "https://firebasestorage.googleapis.com/v0/b/newborn-moments.firebasestorage.app/o/marketing-screenshots%2Fmosaic_batman.png?alt=media&token=5c5b7b5a-5f80-4225-bc10-a12f4d4afa56",
        "https://firebasestorage.googleapis.com/v0/b/newborn-moments.firebasestorage.app/o/marketing-screenshots%2Fmosaic_snow_angel.png?alt=media&token=0e81b05c-601d-4e05-8915-c0e52a365e52"
    ]
    #endif
}
