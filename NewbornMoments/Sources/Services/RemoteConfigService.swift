import FirebaseRemoteConfig

/// Firebase Remote Config wrapper — three flags currently drive real product decisions:
///
/// - "limitedTimeAction": gates HomeViewController's Limited Time Offer popup entirely.
/// - "introPackage": the RevenueCat product id the single-offer paywall should sell (see
///   SingleOfferPaywallViewController) — one of the existing weekly/monthly/yearly subscription
///   products, picked remotely so which tier is "the intro offer" can change without a release.
/// - "frun": whether the single-offer paywall should be shown right after onboarding, and again
///   at the start of every later session (see AppCoordinator).
///
/// `configValue(forKey:)` always returns synchronously — the fetched/activated value if one
/// exists, otherwise the default set below — so nothing here ever blocks on network (Stability
/// Gate rule, same as everywhere else in this app).
enum RemoteConfigService {
    private static let remoteConfig = RemoteConfig.remoteConfig()

    static func configure() {
        let settings = RemoteConfigSettings()
        #if DEBUG
        // Always fetch fresh while iterating — a stale cached value during development would
        // be confusing when testing these flags.
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3600
        #endif
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults([
            "limitedTimeAction": true as NSObject,
            "frun": false as NSObject,
            "rate": false as NSObject,
            "introPackage": "" as NSObject
        ])
        // Fired at launch, non-blocking — by design this may still be in flight the first time
        // AppCoordinator reads a flag (e.g. right after the 1.6s splash), in which case the
        // default above is what's used for that session's routing decision.
        remoteConfig.fetchAndActivate { _, error in
            if let error {
                print("RemoteConfigService.fetchAndActivate failed: \(error)")
            }
        }
    }

    static var isLimitedTimeOfferEnabled: Bool {
        remoteConfig.configValue(forKey: "limitedTimeAction").boolValue
    }

    static var showSingleOfferPaywallOnLaunch: Bool {
        remoteConfig.configValue(forKey: "frun").boolValue
    }

    static var showRate: Bool {
        remoteConfig.configValue(forKey: "rate").boolValue
    }

    /// nil when unset/empty — callers fall back to a sensible default plan rather than failing.
    static var introPackageProductId: String? {
        let value = remoteConfig.configValue(forKey: "introPackage").stringValue
        return value.isEmpty ? nil : value
    }
}
