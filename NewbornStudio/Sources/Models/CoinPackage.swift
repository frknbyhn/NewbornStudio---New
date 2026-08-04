import Foundation

/// Mirrors the real App Store Connect consumable IAPs (see DECISIONS.md).
struct CoinPackage {
    let productId: String
    let name: String
    let credits: Int
    let priceLabel: String
    let isPopular: Bool

    static let all: [CoinPackage] = [
        CoinPackage(productId: "com.newborn.small", name: "Small Pack", credits: 5, priceLabel: "$3.99", isPopular: false),
        CoinPackage(productId: "com.newborn.limited", name: "Limited Time Offer", credits: 25, priceLabel: "$6.99", isPopular: true),
        CoinPackage(productId: "com.newborn.medium", name: "Medium Pack", credits: 15, priceLabel: "$9.99", isPopular: false),
        CoinPackage(productId: "com.newborn.big", name: "Big Pack", credits: 50, priceLabel: "$19.99", isPopular: false)
    ]
}
