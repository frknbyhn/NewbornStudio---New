import UIKit

final class PaywallViewController: UIViewController {
    var onDismiss: (() -> Void)?

    private let scrollView = UIScrollView()
    private var planCards: [PlanCardView] = []
    private var selectedPlan: SubscriptionPlan = SubscriptionPlan.all.first(where: \.isFeatured) ?? SubscriptionPlan.all[0]
    private let billedCaption = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpScrollContent()
        setUpCloseButton()
    }

    private func setUpCloseButton() {
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = Theme.Color.textSecondaryAlt
        close.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        close.layer.cornerRadius = 16
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(close)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            close.widthAnchor.constraint(equalToConstant: 32),
            close.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func setUpScrollContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let content = UIStackView()
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 0
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scrollView.topAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        content.addArrangedSubview(heroView())

        let body = UIStackView()
        body.axis = .vertical
        body.alignment = .fill
        body.spacing = 20
        body.isLayoutMarginsRelativeArrangement = true
        body.layoutMargins = UIEdgeInsets(top: 20, left: 24, bottom: 40, right: 24)
        body.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(body)

        let title = UILabel()
        title.text = "Unlock Unlimited Creativity"
        title.font = Theme.Font.heading(26, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.textAlignment = .center
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = "Everything you need to make forever memories."
        subtitle.font = Theme.Font.body(13.5, weight: 600)
        subtitle.textColor = Theme.Color.textSecondary
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        body.addArrangedSubview(title)
        body.addArrangedSubview(subtitle)
        body.setCustomSpacing(4, after: title)

        let bullets = UIStackView(arrangedSubviews: SubscriptionPlan.benefits.map(benefitRow))
        bullets.axis = .vertical
        bullets.spacing = 11
        body.addArrangedSubview(bullets)

        let plansStack = UIStackView()
        plansStack.axis = .horizontal
        plansStack.spacing = 10
        plansStack.distribution = .fillEqually
        for plan in SubscriptionPlan.all {
            let card = PlanCardView(plan: plan)
            card.isSelectedPlan = plan.productId == selectedPlan.productId
            card.addTarget(self, action: #selector(planTapped(_:)), for: .touchUpInside)
            planCards.append(card)
            plansStack.addArrangedSubview(card)
        }
        body.addArrangedSubview(plansStack)
        body.setCustomSpacing(24, after: plansStack)

        let cta = GradientPillButton(title: "Subscribe Now", icon: nil)
        cta.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
        body.addArrangedSubview(cta)

        billedCaption.font = Theme.Font.body(11, weight: 600)
        billedCaption.textColor = UIColor(hex: 0xB4A6A2)
        billedCaption.textAlignment = .center
        updateBilledCaption()
        body.addArrangedSubview(billedCaption)
        body.setCustomSpacing(10, after: cta)

        let restoreLink = footerLink("Restore")
        (restoreLink as? UIButton)?.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        let termsLink = footerLink("Terms")
        (termsLink as? UIButton)?.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)
        let privacyLink = footerLink("Privacy")
        (privacyLink as? UIButton)?.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)
        let footer = UIStackView(arrangedSubviews: [restoreLink, termsLink, privacyLink])
        footer.axis = .horizontal
        footer.spacing = 18
        footer.alignment = .center
        let footerWrap = UIStackView(arrangedSubviews: [footer])
        footerWrap.axis = .horizontal
        footerWrap.alignment = .center
        body.addArrangedSubview(footerWrap)
        body.setCustomSpacing(14, after: billedCaption)
    }

    private func heroView() -> UIView {
        let container = UIView()
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(hex: 0xFBE1E7).cgColor, UIColor(hex: 0xFFF7F0).cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        container.layer.insertSublayer(gradient, at: 0)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 150).isActive = true
        DispatchQueue.main.async { gradient.frame = container.bounds }

        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = Theme.Color.accentEnd
        icon.contentMode = .scaleAspectFit

        let badge = PaddedLabel()
        badge.text = "NEWBORN PRO"
        badge.horizontalPadding = 14
        badge.font = Theme.Font.heading(11, weight: 700)
        badge.textColor = Theme.Color.accentEnd
        badge.backgroundColor = .white
        badge.layer.cornerRadius = 14
        badge.layer.masksToBounds = true
        badge.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, badge])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 46),
            icon.heightAnchor.constraint(equalToConstant: 46),
            badge.heightAnchor.constraint(equalToConstant: 28),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func benefitRow(_ text: String) -> UIView {
        let iconBackground = UIView()
        iconBackground.backgroundColor = Theme.Color.successBackground
        iconBackground.layer.cornerRadius = 13
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.widthAnchor.constraint(equalToConstant: 26).isActive = true
        iconBackground.heightAnchor.constraint(equalToConstant: 26).isActive = true

        let check = UIImageView(image: UIImage(systemName: "checkmark"))
        check.tintColor = Theme.Color.success
        check.contentMode = .scaleAspectFit
        check.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(check)
        NSLayoutConstraint.activate([
            check.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            check.widthAnchor.constraint(equalToConstant: 13),
            check.heightAnchor.constraint(equalToConstant: 13)
        ])

        let label = UILabel()
        label.text = text
        label.font = Theme.Font.body(14.5, weight: 600)
        label.textColor = Theme.Color.textSecondaryAlt

        let row = UIStackView(arrangedSubviews: [iconBackground, label])
        row.axis = .horizontal
        row.spacing = 11
        row.alignment = .center
        return row
    }

    private func footerLink(_ title: String) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(Theme.Color.textSecondary, for: .normal)
        button.titleLabel?.font = Theme.Font.body(12, weight: 600)
        return button
    }

    private func updateBilledCaption() {
        billedCaption.text = "Billed \(selectedPlan.priceLabel) \(selectedPlan.title == "Weekly" ? "weekly" : selectedPlan.title == "Monthly" ? "monthly" : "yearly") · Cancel anytime"
    }

    @objc private func planTapped(_ sender: PlanCardView) {
        HapticFeedback.selection()
        selectedPlan = sender.plan
        for card in planCards { card.isSelectedPlan = card.plan.productId == sender.plan.productId }
        updateBilledCaption()
    }

    @objc private func subscribeTapped() {
        // RevenueCat purchase flow wires in here in Phase 7.
        HapticFeedback.success()
        closeTapped()
    }

    @objc private func closeTapped() {
        onDismiss?()
    }

    @objc private func restoreTapped() {
        // Wired to Purchases.shared.restorePurchases in Phase 7 (RevenueCat).
        HapticFeedback.light()
    }

    @objc private func termsTapped() {
        HapticFeedback.light()
        present(UINavigationController(rootViewController: LegalDocumentViewController(title: "Terms of Use")), animated: true)
    }

    @objc private func privacyTapped() {
        HapticFeedback.light()
        present(UINavigationController(rootViewController: LegalDocumentViewController(title: "Privacy Policy")), animated: true)
    }
}
