import RevenueCat
import FirebaseFunctions

enum RevenueCatService {
    // Public SDK key — safe to ship in the client. This RevenueCat project hosts several other
    // apps; the "newborn" offering is fetched by its own identifier below rather than relying on
    // offerings.current, which is a project-wide flag shared across every app in the account.
    private static let publicAPIKey = "appl_nxpqIXSXIpYQrsdRfrQwIpDxBrs"
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
