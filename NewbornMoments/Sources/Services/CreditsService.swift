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
        #if DEBUG
        if ProcessInfo.processInfo.environment["NS_DEBUG_PRINT_UID"] != nil {
            NSLog("NS_DEBUG_UID=%@", uid)
        }
        #endif
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
    ///
    /// This is the ≥1 case — most generations cost exactly 1 credit up front from the user's
    /// perspective (the server enforces the style's real cost regardless), so a soft "has
    /// something" check has been enough. A multi-credit action (e.g. a collage costing N items'
    /// worth of credits) needs the amount-aware overload below instead, or this same soft check
    /// would let someone through here only to hit a real "insufficient credits" failure
    /// server-side — see requireCredits(atLeast:presentingFrom:onAllowed:).
    static func requireCredits(presentingFrom viewController: UIViewController, onAllowed: @escaping () -> Void) {
        requireCredits(atLeast: 1, presentingFrom: viewController, onAllowed: onAllowed)
    }

    /// Same gate, but checks for a specific amount rather than just "> 0" — for an action whose
    /// cost the client already knows up front (e.g. MilestoneListDetailViewController's collage
    /// button, N credits for N items) and wants to route to the paywall/coin screen itself
    /// instead of letting the user tap through only to have the server reject it.
    static func requireCredits(atLeast amount: Int, presentingFrom viewController: UIViewController, onAllowed: @escaping () -> Void) {
        fetchStatus { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let status):
                    if status.totalCredits >= amount {
                        onAllowed()
                    } else if status.isPremium {
                        viewController.present(CoinPackageViewController.presented(), animated: true)
                    } else {
                        viewController.present(PaywallViewController.presented(), animated: true)
                    }
                case .failure(let error):
                    print("CreditsService.fetchStatus failed: \(error)")
                    let alert = UIAlertController(
                        title: NSLocalizedString("Couldn't check your credits", comment: "Credits fetch failure alert title"),
                        message: NSLocalizedString("Please check your connection and try again.", comment: "Credits fetch failure alert message"),
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .default))
                    viewController.present(alert, animated: true)
                }
            }
        }
    }
}
