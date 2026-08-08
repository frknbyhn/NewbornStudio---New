import Foundation
import RevenueCat

/// Built from a real RevenueCat `Package` (custom identifiers: "small", "limited", "medium", "big").
/// Credit amounts are display-only here — see functions/helpers/purchaseGrants.js for the source of truth.
struct CoinPackage {
    let package: Package
    let name: String
    let credits: Int
    let priceLabel: String
    let isPopular: Bool

    var productId: String { package.storeProduct.productIdentifier }

    init(package: Package) {
        self.package = package
        self.priceLabel = package.storeProduct.localizedPriceString
        switch package.identifier {
        case "small":
            name = NSLocalizedString("Small Pack", comment: "Coin package name")
            credits = 5
            isPopular = false
        case "limited":
            name = NSLocalizedString("Limited Time Offer", comment: "Coin package name")
            credits = 25
            isPopular = true
        case "medium":
            name = NSLocalizedString("Medium Pack", comment: "Coin package name")
            credits = 15
            isPopular = false
        case "big":
            name = NSLocalizedString("Big Pack", comment: "Coin package name")
            credits = 50
            isPopular = false
        default:
            name = package.storeProduct.localizedTitle
            credits = 0
            isPopular = false
        }
    }
}
