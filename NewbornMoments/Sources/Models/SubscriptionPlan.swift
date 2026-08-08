import Foundation
import RevenueCat

/// Built from a real RevenueCat `Package` — display-only mapping of product id -> credit
/// wording. The actual grant amounts live server-side in functions/helpers/purchaseGrants.js;
/// this must stay in sync with that file but granting itself never trusts the client's copy.
struct SubscriptionPlan {
    let package: Package
    let title: String
    let priceLabel: String
    let periodLabel: String
    let creditsLabel: String
    let badge: String?
    let isFeatured: Bool

    var productId: String { package.storeProduct.productIdentifier }

    init(package: Package) {
        self.package = package
        let product = package.storeProduct
        self.priceLabel = product.localizedPriceString

        switch package.packageType {
        case .weekly:
            title = NSLocalizedString("Weekly", comment: "Subscription plan title")
            periodLabel = NSLocalizedString("per week", comment: "Subscription plan period")
            creditsLabel = NSLocalizedString("10 credits / week", comment: "Subscription plan credits")
            badge = nil
            isFeatured = false
        case .monthly:
            title = NSLocalizedString("Monthly", comment: "Subscription plan title")
            periodLabel = NSLocalizedString("per month", comment: "Subscription plan period")
            creditsLabel = NSLocalizedString("50 credits / month", comment: "Subscription plan credits")
            badge = nil
            isFeatured = false
        case .annual:
            title = NSLocalizedString("Yearly", comment: "Subscription plan title")
            periodLabel = product.localizedPricePerWeek.map { String(format: NSLocalizedString("%@ / week", comment: "Per-week price breakdown, %@ is a formatted price"), $0) } ?? NSLocalizedString("per year", comment: "Subscription plan period")
            creditsLabel = NSLocalizedString("500 credits / year", comment: "Subscription plan credits")
            badge = nil
            isFeatured = true
        default:
            title = product.localizedTitle
            periodLabel = ""
            creditsLabel = ""
            badge = nil
            isFeatured = false
        }
    }

    static let benefits: [String] = [
        NSLocalizedString("Unlimited studio themes", comment: "Paywall benefit"),
        NSLocalizedString("Priority AI generation", comment: "Paywall benefit"),
        NSLocalizedString("Save every portrait to your gallery", comment: "Paywall benefit"),
        NSLocalizedString("No watermark", comment: "Paywall benefit")
    ]
}
