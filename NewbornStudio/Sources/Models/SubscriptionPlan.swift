import Foundation

/// Mirrors the real App Store Connect products (see DECISIONS.md) — the RevenueCat
/// offering replaces this hardcoded list in Phase 7, this is the data-shape placeholder.
struct SubscriptionPlan {
    let productId: String
    let title: String
    let priceLabel: String
    let periodLabel: String
    let creditsLabel: String
    let badge: String?
    let isFeatured: Bool

    static let all: [SubscriptionPlan] = [
        SubscriptionPlan(
            productId: "com.newborn.weekly",
            title: "Weekly",
            priceLabel: "$4.99",
            periodLabel: "per week",
            creditsLabel: "10 credits / week",
            badge: nil,
            isFeatured: false
        ),
        SubscriptionPlan(
            productId: "com.newborn.monthly",
            title: "Monthly",
            priceLabel: "$14.99",
            periodLabel: "per month",
            creditsLabel: "50 credits / month",
            badge: "3-day trial",
            isFeatured: false
        ),
        SubscriptionPlan(
            productId: "com.newborn.yearly",
            title: "Yearly",
            priceLabel: "$49.99",
            periodLabel: "$0.96 / week",
            creditsLabel: "500 credits / year",
            badge: "Best value",
            isFeatured: true
        )
    ]

    static let benefits: [String] = [
        "Unlimited studio themes",
        "Priority AI generation",
        "Save every portrait to your gallery",
        "No watermark"
    ]
}
