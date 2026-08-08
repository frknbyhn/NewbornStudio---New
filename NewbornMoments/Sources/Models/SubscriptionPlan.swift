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
            title = "Weekly"
            periodLabel = "per week"
            creditsLabel = "10 credits / week"
            badge = nil
            isFeatured = false
        case .monthly:
            title = "Monthly"
            periodLabel = "per month"
            creditsLabel = "50 credits / month"
            badge = nil
            isFeatured = false
        case .annual:
            title = "Yearly"
            periodLabel = product.localizedPricePerWeek.map { "\($0) / week" } ?? "per year"
            creditsLabel = "500 credits / year"
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
        "Unlimited studio themes",
        "Priority AI generation",
        "Save every portrait to your gallery",
        "No watermark"
    ]
}
