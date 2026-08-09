import UIKit

/// Plan info shown by SingleOfferPaywallViewController — deliberately plain text, not a card
/// (no border/background/corner radius): there's exactly one plan and nothing to pick, so it
/// reads as a simple price line rather than a selectable option, directly above the CTA.
final class SinglePlanInfoView: UIView {
    init(plan: SubscriptionPlan) {
        super.init(frame: .zero)

        let titleLabel = UILabel()
        titleLabel.text = plan.title
        titleLabel.font = Theme.Font.heading(15, weight: 700)
        titleLabel.textColor = Theme.Color.textPrimaryAlt

        let creditsLabel = UILabel()
        creditsLabel.text = plan.creditsLabel
        creditsLabel.font = Theme.Font.body(12, weight: 700)
        creditsLabel.textColor = Theme.Color.accentEnd

        let leftStack = UIStackView(arrangedSubviews: [titleLabel, creditsLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 3
        leftStack.alignment = .leading

        let priceLabel = UILabel()
        priceLabel.text = plan.priceLabel
        priceLabel.font = Theme.Font.heading(17, weight: 700)
        priceLabel.textColor = Theme.Color.textPrimaryAlt
        priceLabel.textAlignment = .right

        let periodLabel = UILabel()
        periodLabel.text = plan.periodLabel
        periodLabel.font = Theme.Font.body(11, weight: 600)
        periodLabel.textColor = Theme.Color.textSecondary
        periodLabel.textAlignment = .right

        let rightStack = UIStackView(arrangedSubviews: [priceLabel, periodLabel])
        rightStack.axis = .vertical
        rightStack.spacing = 2
        rightStack.alignment = .trailing

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [leftStack, spacer, rightStack])
        row.axis = .horizontal
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
