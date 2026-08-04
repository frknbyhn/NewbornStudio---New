import UIKit
import FirebaseFirestore

struct CreditStatus {
    let totalCredits: Int
    let isPremium: Bool
    var hasCredits: Bool { totalCredits > 0 }
}

enum CreditsServiceError: Error {
    case notSignedIn
}

enum CreditsService {
    static func fetchStatus(completion: @escaping (Result<CreditStatus, Error>) -> Void) {
        #if DEBUG
        // Screenshot-verification aid only — never reachable in a release build.
        if let forced = ProcessInfo.processInfo.environment["NS_DEBUG_CREDITS"] {
            switch forced {
            case "none-free": completion(.success(CreditStatus(totalCredits: 0, isPremium: false))); return
            case "none-premium": completion(.success(CreditStatus(totalCredits: 0, isPremium: true))); return
            case "has": completion(.success(CreditStatus(totalCredits: 5, isPremium: false))); return
            default: break
            }
        }
        #endif
        guard let uid = AuthService.currentUserId else {
            completion(.failure(CreditsServiceError.notSignedIn))
            return
        }
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            let data = snapshot?.data() ?? [:]
            let subscriptionCredits = data["subscriptionCredits"] as? Int ?? 0
            let purchasedCredits = data["purchasedCredits"] as? Int ?? 0
            let isPremium = data["isPremium"] as? Bool ?? false
            completion(.success(CreditStatus(totalCredits: subscriptionCredits + purchasedCredits, isPremium: isPremium)))
        }
    }

    /// Gate to call right before a generation is actually kicked off. Has credits → proceeds
    /// immediately. No credits and not subscribed → subscription paywall. No credits but
    /// subscribed (their period ran dry) → coin purchase screen, since another subscription
    /// wouldn't grant more credits until the next renewal.
    static func requireCredits(presentingFrom viewController: UIViewController, onAllowed: @escaping () -> Void) {
        fetchStatus { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let status):
                    if status.hasCredits {
                        onAllowed()
                    } else if status.isPremium {
                        viewController.navigationController?.pushViewController(CoinPackageViewController(), animated: true)
                    } else {
                        let paywall = PaywallViewController()
                        paywall.modalPresentationStyle = .fullScreen
                        paywall.onDismiss = { [weak paywall] in
                            paywall?.dismiss(animated: true)
                        }
                        viewController.present(paywall, animated: true)
                    }
                case .failure(let error):
                    print("CreditsService.fetchStatus failed: \(error)")
                    let alert = UIAlertController(
                        title: "Couldn't check your credits",
                        message: "Please check your connection and try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    viewController.present(alert, animated: true)
                }
            }
        }
    }
}
