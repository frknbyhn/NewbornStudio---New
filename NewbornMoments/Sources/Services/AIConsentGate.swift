import UIKit

/// One-time AI data-consent gate (App Store 5.1.1(i)/5.1.2(i)): before any photo can be sent to
/// wiro.ai for generation, the user must accept the AIConsentViewController disclosure once.
///
/// Two entry points, both used by every photo-upload screen:
/// - `presentIfNeeded(from:)` — shown when the screen appears. Dismissible (tapping the backdrop
///   closes it) — closing just defers the decision, it doesn't grant.
/// - `requireConsent(from:then:)` — the hard gate at the actual upload action (opening the picker,
///   reusing a recent photo). If consent exists it runs the action immediately; otherwise it shows
///   the sheet and runs the action *only* once the user accepts. Dismissing without accepting does
///   nothing, so no photo can be uploaded without consent.
/// Once granted it's persisted and never shown again.
enum AIConsentGate {
    private static let defaultsKey = "aiPhotoConsentGranted_v1"

    static var isGranted: Bool { UserDefaults.standard.bool(forKey: defaultsKey) }

    static func grant() { UserDefaults.standard.set(true, forKey: defaultsKey) }

    /// Soft, screen-appear prompt. No-op once consent exists (or while something is already presented).
    static func presentIfNeeded(from viewController: UIViewController) {
        guard !isGranted else { return }
        present(from: viewController, onGranted: nil)
    }

    /// Hard gate at the upload action. Runs `action` right away if consent exists; otherwise shows
    /// the sheet and runs `action` only after the user accepts.
    static func requireConsent(from viewController: UIViewController, then action: @escaping () -> Void) {
        guard !isGranted else {
            action()
            return
        }
        present(from: viewController, onGranted: action)
    }

    private static func present(from viewController: UIViewController, onGranted: (() -> Void)?) {
        guard viewController.presentedViewController == nil else { return }
        let consent = AIConsentViewController()
        consent.onAccepted = { [weak viewController] in
            grant()
            viewController?.presentedViewController?.dismiss(animated: true) {
                onGranted?()
            }
        }
        viewController.present(consent, animated: true)
    }
}
