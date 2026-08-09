import Foundation
import RevenueCat
import FirebaseFunctions

extension Notification.Name {
    /// Posted right after any purchase (coin pack, limited offer, subscription) is granted
    /// server-side — credits/premium status just changed. Screens showing a credit balance
    /// (currently just HomeViewController's coin pill) observe this instead of relying on
    /// viewWillAppear/viewDidAppear timing after a purchase screen dismisses, which isn't
    /// reliable here: these purchase screens are presented with `self.present(...)` from deep in
    /// a tab's view controller hierarchy, so modal presentation can bubble up past the screen
    /// that actually needs to refresh, and its own appearance callbacks never fire again.
    static let creditsDidChange = Notification.Name("creditsDidChange")
}

enum RevenueCatService {
    // Public SDK key — safe to ship in the client. This RevenueCat project hosts several other
    // apps; the "newborn" offering is fetched by its own identifier below rather than relying on
    // offerings.current, which is a project-wide flag shared across every app in the account.
    // "newborn" is a lookup key reused from the account's shared entitlement (see memory) — it
    // isn't user-facing, so keeping it doesn't conflict with the Newborn Moments rebrand.
    private static let publicAPIKey = "appl_KezTVkyDqqcvBlcgJFzTLgfKdhf"
    private static let offeringIdentifier = "newborn"
    private static let entitlementIdentifier = "newborn"

    static func configure() {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: publicAPIKey)
    }

    /// Call once AuthService has a uid, so RevenueCat's app_user_id matches the Firestore uid.
    static func identify(uid: String) {
        Purchases.shared.logIn(uid) { _, _, _ in }
    }

    static func fetchOffering(completion: @escaping (Result<Offering, Error>) -> Void) {
        Purchases.shared.getOfferings { offerings, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let offering = offerings?.offering(identifier: offeringIdentifier) else {
                completion(.failure(RevenueCatServiceError.offeringNotFound))
                return
            }
            completion(.success(offering))
        }
    }

    static func purchase(package: Package, completion: @escaping (Result<PurchaseGrant, Error>) -> Void) {
        Purchases.shared.purchase(package: package) { _, customerInfo, error, userCancelled in
            if userCancelled {
                completion(.failure(RevenueCatServiceError.userCancelled))
                return
            }
            if let error {
                completion(.failure(error))
                return
            }
            grantPurchase(productId: package.storeProduct.productIdentifier, completion: completion)
        }
    }

    /// Cheap "is this user already subscribed?" check — same definition as restoreTapped's own
    /// check (a non-empty active entitlement set). Used by AppCoordinator to skip the
    /// single-offer paywall for anyone who's already subscribed. RevenueCat serves this from its
    /// local cache when possible, so this rarely if ever hits the network.
    static func isPremium(completion: @escaping (Bool) -> Void) {
        Purchases.shared.getCustomerInfo { customerInfo, error in
            guard let customerInfo, error == nil else {
                completion(false)
                return
            }
            completion(!customerInfo.entitlements.active.isEmpty)
        }
    }

    static func restore(completion: @escaping (Result<CustomerInfo, Error>) -> Void) {
        Purchases.shared.restorePurchases { customerInfo, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let customerInfo else {
                completion(.failure(RevenueCatServiceError.offeringNotFound))
                return
            }
            completion(.success(customerInfo))
        }
    }

    /// Client-side grant, not a webhook — playbook Phase 7 rule: a webhook-only flow delays the
    /// credits the user just paid for, which reads to Apple as "purchases don't work."
    private static func grantPurchase(productId: String, completion: @escaping (Result<PurchaseGrant, Error>) -> Void) {
        Functions.functions().httpsCallable("grantPurchase").call(["productId": productId]) { result, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let dict = result?.data as? [String: Any] else {
                completion(.failure(RevenueCatServiceError.offeringNotFound))
                return
            }
            let grant = PurchaseGrant(
                isPremium: dict["isPremium"] as? Bool ?? false,
                subscriptionCredits: dict["subscriptionCredits"] as? Int ?? 0,
                purchasedCredits: dict["purchasedCredits"] as? Int ?? 0
            )
            NotificationCenter.default.post(name: .creditsDidChange, object: nil)
            completion(.success(grant))
        }
    }
}

struct PurchaseGrant {
    let isPremium: Bool
    let subscriptionCredits: Int
    let purchasedCredits: Int
}

enum RevenueCatServiceError: Error {
    case offeringNotFound
    case userCancelled
}
