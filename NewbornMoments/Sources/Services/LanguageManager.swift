import UIKit
import ObjectiveC

/// Bundle subclass installed in place of `Bundle.main` (via `object_setClass`, see
/// `LanguageManager.installSwizzleIfNeeded`) so every existing `NSLocalizedString` call in the
/// app — there's no other localization mechanism here — transparently resolves against whatever
/// `.lproj` the user picked, instead of the device's own preferred language. `.OBJC_ASSOCIATION`
/// storage (rather than a stored property) is required: swizzling replaces the class of the
/// existing `Bundle.main` singleton in place, it doesn't create a subclass instance normally.
private var overrideBundlePathKey: UInt8 = 0

private final class LanguageOverrideBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let path = objc_getAssociatedObject(self, &overrideBundlePathKey) as? String,
              let overrideBundle = Bundle(path: path) else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return overrideBundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

/// Lets the user override the app's display language from Settings, applied instantly (no
/// relaunch) — see LanguageListViewController. Persists the choice so it survives the next
/// launch too.
enum LanguageManager {
    private static let overrideDefaultsKey = "NS_LanguageOverride"

    /// code → native display name, in the order shown in the picker. Codes match exactly what's
    /// in Localizable.xcstrings (and therefore the .lproj folders actually built into the app) —
    /// "en" is the String Catalog's source language and has no localizations entry of its own,
    /// but still ships its own en.lproj like every other locale.
    static let supported: [(code: String, name: String)] = [
        ("en", "English"),
        ("ar", "العربية"),
        ("ca", "Català"),
        ("zh-Hans", "简体中文"),
        ("zh-Hant", "繁體中文"),
        ("hr", "Hrvatski"),
        ("cs", "Čeština"),
        ("da", "Dansk"),
        ("nl", "Nederlands"),
        ("fi", "Suomi"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("el", "Ελληνικά"),
        ("he", "עברית"),
        ("hi", "हिन्दी"),
        ("hu", "Magyar"),
        ("id", "Bahasa Indonesia"),
        ("it", "Italiano"),
        ("ja", "日本語"),
        ("ko", "한국어"),
        ("ms", "Bahasa Melayu"),
        ("nb", "Norsk bokmål"),
        ("pl", "Polski"),
        ("pt", "Português"),
        ("ro", "Română"),
        ("ru", "Русский"),
        ("sk", "Slovenčina"),
        ("es", "Español"),
        ("sv", "Svenska"),
        ("th", "ไทย"),
        ("tr", "Türkçe"),
        ("uk", "Українська"),
        ("vi", "Tiếng Việt")
    ]

    /// The active language code — the user's explicit override if they ever set one, otherwise
    /// whatever `Bundle.main` would naturally resolve to (device preference ∩ supported set).
    static var currentCode: String {
        if let stored = UserDefaults.standard.string(forKey: overrideDefaultsKey) {
            return stored
        }
        let preferred = Bundle.main.preferredLocalizations.first ?? "en"
        return supported.contains { $0.code == preferred } ? preferred : "en"
    }

    static var currentDisplayName: String {
        supported.first { $0.code == currentCode }?.name ?? "English"
    }

    /// Call once at app launch, before any UI (and therefore any NSLocalizedString call) is
    /// built — installs the swizzle and re-applies a previously chosen override, if any.
    static func bootstrap() {
        installSwizzleIfNeeded()
        if let stored = UserDefaults.standard.string(forKey: overrideDefaultsKey) {
            apply(stored)
        }
    }

    /// Applies a new language immediately: persists the choice, points the swizzled bundle at
    /// the new .lproj, then asks AppCoordinator to rebuild the whole UI tree from scratch so
    /// every already-rendered label picks up the new strings — a Bundle override alone only
    /// affects labels set *after* this call, not the ones already on screen.
    static func setLanguage(_ code: String) {
        UserDefaults.standard.set(code, forKey: overrideDefaultsKey)
        installSwizzleIfNeeded()
        apply(code)
        AppCoordinator.shared?.reloadForLanguageChange()
    }

    private static func installSwizzleIfNeeded() {
        guard object_getClass(Bundle.main) != LanguageOverrideBundle.self else { return }
        object_setClass(Bundle.main, LanguageOverrideBundle.self)
    }

    private static func apply(_ code: String) {
        let path = Bundle.main.path(forResource: code, ofType: "lproj")
        objc_setAssociatedObject(Bundle.main, &overrideBundlePathKey, path, .OBJC_ASSOCIATION_RETAIN)
    }
}
