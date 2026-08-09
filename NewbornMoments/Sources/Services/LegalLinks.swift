import Foundation

/// The app's Privacy Policy / Terms of Use — hosted on Firebase (see public/privacy.html,
/// public/terms.html), opened directly in the browser via UIApplication.open from every
/// "Privacy"/"Terms" link in the app (Profile, both paywalls, the coin package screen).
/// Replaces the removed in-app LegalDocumentViewController.
enum LegalLinks {
    static let privacyPolicy = URL(string: "https://newborn-moments.web.app/privacy.html")!
    static let termsOfUse = URL(string: "https://newborn-moments.web.app/terms.html")!
}
