import Foundation

/// Drives the one-time "Limited Time Offer" coin pack popup: a real 6-hour deadline that
/// persists across app launches/sessions (not reset each session), shown at most once per
/// session, plus one final "you missed it" showing right after the deadline passes.
enum LimitedOfferService {
    private static let defaults = UserDefaults.standard
    private static let deadlineKey = "limitedOfferDeadline"
    private static let purchasedKey = "limitedOfferPurchased"
    private static let expiredShownKey = "limitedOfferExpiredShownOnce"

    /// In-memory only — deliberately not persisted, so "once per session" means once per
    /// process launch rather than once ever.
    private static var shownThisLaunch = false

    enum PopupState {
        case active(remaining: TimeInterval)
        case justExpired
    }

    static func popupStateForThisLaunch() -> PopupState? {
        #if DEBUG
        // Screenshot-verification aid only — never reachable in a release build.
        if let forced = ProcessInfo.processInfo.environment["NS_DEBUG_LIMITED_OFFER"] {
            defaults.removeObject(forKey: deadlineKey)
            defaults.set(false, forKey: purchasedKey)
            defaults.set(false, forKey: expiredShownKey)
            switch forced {
            case "active":
                defaults.set(Date().addingTimeInterval(6 * 3600), forKey: deadlineKey)
            case "expired":
                defaults.set(Date().addingTimeInterval(-1), forKey: deadlineKey)
            case "purchased":
                defaults.set(true, forKey: purchasedKey)
            default: break
            }
        }
        #endif
        guard !shownThisLaunch, !defaults.bool(forKey: purchasedKey) else { return nil }

        let deadline: Date
        if let stored = defaults.object(forKey: deadlineKey) as? Date {
            deadline = stored
        } else {
            deadline = Date().addingTimeInterval(6 * 3600)
            defaults.set(deadline, forKey: deadlineKey)
        }

        let remaining = deadline.timeIntervalSinceNow
        if remaining > 0 {
            shownThisLaunch = true
            return .active(remaining: remaining)
        }

        guard !defaults.bool(forKey: expiredShownKey) else { return nil }
        shownThisLaunch = true
        defaults.set(true, forKey: expiredShownKey)
        return .justExpired
    }

    static func markPurchased() {
        defaults.set(true, forKey: purchasedKey)
    }
}
