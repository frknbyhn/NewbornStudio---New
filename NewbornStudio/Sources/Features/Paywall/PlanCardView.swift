import UIKit

final class PlanCardView: UIControl {
    let plan: SubscriptionPlan
    private let badgeLabel = UILabel()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let periodLabel = UILabel()
    private let creditsLabel = UILabel()

    var isSelectedPlan: Bool = false {
        didSet { updateSelection() }
    }

    init(plan: SubscriptionPlan) {
        self.plan = plan
        super.init(frame: .zero)
        setUp()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUp() {
        layer.cornerRadius = Theme.Shape.cardRadius
        layer.borderWidth = 1.5

        titleLabel.text = plan.title
        titleLabel.font = Theme.Font.heading(14, weight: 700)
        titleLabel.textAlignment = .center

        priceLabel.text = plan.priceLabel
        priceLabel.font = Theme.Font.heading(15, weight: 700)
        priceLabel.textColor = Theme.Color.textPrimaryAlt
        priceLabel.textAlignment = .center

        periodLabel.text = plan.periodLabel
        periodLabel.font = Theme.Font.body(11, weight: 600)
        periodLabel.textColor = Theme.Color.textSecondary
        periodLabel.textAlignment = .center

        creditsLabel.text = plan.creditsLabel
        creditsLabel.font = Theme.Font.body(11, weight: 700)
        creditsLabel.textColor = Theme.Color.accentEnd
        creditsLabel.textAlignment = .center
        creditsLabel.numberOfLines = 1
        creditsLabel.adjustsFontSizeToFitWidth = true
        creditsLabel.minimumScaleFactor = 0.8

        let stack = UIStackView(arrangedSubviews: [titleLabel, priceLabel, periodLabel, creditsLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.setCustomSpacing(8, after: periodLabel)
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 108)
        ])

        if let badge = plan.badge {
            badgeLabel.text = badge.uppercased()
            badgeLabel.font = Theme.Font.heading(8.5, weight: 700)
            badgeLabel.textColor = .white
            badgeLabel.textAlignment = .center
            badgeLabel.numberOfLines = 1
            badgeLabel.adjustsFontSizeToFitWidth = true
            badgeLabel.minimumScaleFactor = 0.75
            badgeLabel.backgroundColor = Theme.Color.accentEnd
            badgeLabel.layer.cornerRadius = 9
            badgeLabel.layer.masksToBounds = true
            badgeLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(badgeLabel)
            bringSubviewToFront(badgeLabel)
            NSLayoutConstraint.activate([
                badgeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                badgeLabel.topAnchor.constraint(equalTo: topAnchor, constant: -10),
                badgeLabel.heightAnchor.constraint(equalToConstant: 18),
                badgeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
                badgeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2)
            ])
        }

        updateSelection()
    }

    private func updateSelection() {
        if isSelectedPlan {
            layer.borderColor = Theme.Color.accentEnd.cgColor
            backgroundColor = UIColor(hex: 0xFFF4F1)
        } else {
            layer.borderColor = UIColor(hex: 0xEEE3DB).cgColor
            backgroundColor = .white
        }
    }
}
