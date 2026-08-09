import UIKit

/// Plan info shown by SingleOfferPaywallViewController — one plan, nothing to pick, so instead of
/// PlanCardView's card (title/credits on one side, price/period on the other) this reads
/// top-to-bottom as a short, centered story: how much → what it includes. No card chrome, sits
/// directly above the CTA. Also owns the benefit bullets (moved here from the screen's own
/// textBlock()) — grouping "what you get" with "what it costs" reads as one pitch instead of two
/// disconnected blocks.
final class SinglePlanInfoView: UIView {
    init(plan: SubscriptionPlan) {
        super.init(frame: .zero)

        let eyebrowLabel = UILabel()
        eyebrowLabel.attributedText = NSAttributedString(
            string: plan.title.uppercased(),
            attributes: [
                .font: Theme.Font.body(30, weight: 700),
                .foregroundColor: Theme.Color.textPrimary,
                .kern: 1.4
            ]
        )
        eyebrowLabel.textAlignment = .center

        // Price and period share one line but stay visually distinct through size/weight alone —
        // the price is the whole point of this view, so it's the only thing at full heading size.
        let priceText = NSMutableAttributedString(
            string: plan.priceLabel,
            attributes: [.font: Theme.Font.heading(18, weight: 700), .foregroundColor: Theme.Color.textSecondary]
        )
        let priceLabel = UILabel()
        priceLabel.attributedText = priceText
        priceLabel.textAlignment = .center

        let creditsLabel = PaddedLabel()
        creditsLabel.text = plan.creditsLabel
        creditsLabel.horizontalPadding = 14
        creditsLabel.verticalPadding = 8
        creditsLabel.font = Theme.Font.body(12, weight: 700)
        creditsLabel.textColor = Theme.Color.accentEnd
        creditsLabel.backgroundColor = UIColor(hex: 0xFFF4F1)
        creditsLabel.layer.cornerRadius = 14
        creditsLabel.layer.masksToBounds = true
        creditsLabel.textAlignment = .center

        let priceStack = UIStackView(arrangedSubviews: [priceLabel, creditsLabel])
        priceStack.axis = .vertical
        priceStack.alignment = .center
        priceStack.spacing = 8
        priceStack.setCustomSpacing(2, after: eyebrowLabel)

        let bullets = UIStackView(arrangedSubviews: SubscriptionPlan.benefits.map(benefitRow))
        bullets.axis = .vertical
        bullets.spacing = 9

        let stack = UIStackView(arrangedSubviews: [bullets, priceStack])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Moved from SingleOfferPaywallViewController — same checkmark-row look the main paywall
    /// uses, unchanged.
    private func benefitRow(_ text: String) -> UIView {
        let iconBackground = UIView()
        iconBackground.backgroundColor = Theme.Color.successBackground
        iconBackground.layer.cornerRadius = 12
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconBackground.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let check = UIImageView(image: UIImage(systemName: "checkmark"))
        check.tintColor = Theme.Color.success
        check.contentMode = .scaleAspectFit
        check.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(check)
        NSLayoutConstraint.activate([
            check.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            check.widthAnchor.constraint(equalToConstant: 12),
            check.heightAnchor.constraint(equalToConstant: 12)
        ])

        let label = UILabel()
        label.text = text
        label.font = Theme.Font.body(13.5, weight: 600)
        label.textColor = Theme.Color.textSecondaryAlt

        let row = UIStackView(arrangedSubviews: [iconBackground, label])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        return row
    }
}
