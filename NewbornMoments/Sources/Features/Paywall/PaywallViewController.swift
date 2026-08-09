import UIKit
import RevenueCat

final class PaywallViewController: UIViewController {
    var onDismiss: (() -> Void)?

    /// Every paywall in the app is presented modally (never pushed), full screen, with a
    /// self-dismissing close button — this factory is the one place that wiring lives.
    static func presented() -> PaywallViewController {
        let paywall = PaywallViewController()
        paywall.modalPresentationStyle = .fullScreen
        paywall.onDismiss = { [weak paywall] in
            paywall?.dismiss(animated: true)
        }
        return paywall
    }

    private let spinner = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    private let contentContainer = UIView()
    private var plansStack: UIStackView!
    private var planCards: [PlanCardView] = []
    private var plans: [SubscriptionPlan] = []
    private var selectedPlan: SubscriptionPlan?
    private let cta = GradientPillButton(title: NSLocalizedString("Subscribe Now", comment: "Paywall CTA button"), icon: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpContent()
        setUpCloseButton()
        setUpLoadingState()
        loadOffering()
    }

    private func setUpLoadingState() {
        spinner.color = Theme.Color.accentEnd
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        errorLabel.font = Theme.Font.body(13, weight: 600)
        errorLabel.textColor = Theme.Color.textSecondary
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        spinner.startAnimating()
        contentContainer.isHidden = true
    }

    private func loadOffering() {
        RevenueCatService.fetchOffering { [weak self] result in
            DispatchQueue.main.async {
                self?.handleOffering(result)
            }
        }
    }

    private func handleOffering(_ result: Result<RevenueCat.Offering, Error>) {
        spinner.stopAnimating()
        switch result {
        case .success(let offering):
            // The "newborn" offering holds every package (subscriptions AND consumable coin
            // packs) — the paywall only shows the subscription tiers, Coin Package shows the rest.
            let displayOrder: [PackageType] = [.weekly, .monthly, .annual]
            plans = offering.availablePackages
                .filter { displayOrder.contains($0.packageType) }
                .sorted { displayOrder.firstIndex(of: $0.packageType)! < displayOrder.firstIndex(of: $1.packageType)! }
                .map(SubscriptionPlan.init(package:))
            selectedPlan = plans.first(where: \.isFeatured) ?? plans.first
            populatePlanCards()
            contentContainer.isHidden = false
        case .failure(let error):
            // Real offline/error state — never an infinite spinner (Stability Gate rule).
            errorLabel.text = NSLocalizedString("Couldn't load plans. Check your connection and try again.", comment: "Paywall load error")
            errorLabel.isHidden = false
            print("RevenueCatService.fetchOffering failed: \(error)")
        }
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

    /// Deliberately not a UIScrollView — the whole paywall must fit on one non-scrolling
    /// screen. Bottom-up anchoring (footer -> CTA -> plans) so those stay pinned to the bottom
    /// regardless of how tall the top content (hero/title/bullets) ends up being.
    private func setUpContent() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainer)
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let restoreLink = footerLink(NSLocalizedString("Restore", comment: "Paywall footer link"))
        (restoreLink as? UIButton)?.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        let termsLink = footerLink(NSLocalizedString("Terms", comment: "Paywall footer link"))
        (termsLink as? UIButton)?.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)
        let privacyLink = footerLink(NSLocalizedString("Privacy", comment: "Paywall footer link"))
        (privacyLink as? UIButton)?.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)
        let footer = UIStackView(arrangedSubviews: [restoreLink, termsLink, privacyLink])
        footer.axis = .horizontal
        footer.alignment = .center
        footer.distribution = .equalSpacing
        footer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(footer)

        cta.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
        cta.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(cta)

        plansStack = UIStackView()
        plansStack.axis = .horizontal
        plansStack.spacing = 10
        plansStack.distribution = .fillEqually
        plansStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(plansStack)

        let topStack = UIStackView(arrangedSubviews: [heroView(), textBlock()])
        topStack.axis = .vertical
        topStack.alignment = .fill
        topStack.spacing = 16
        topStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(topStack)

        NSLayoutConstraint.activate([
            footer.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 40),
            footer.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -40),
            footer.bottomAnchor.constraint(equalTo: contentContainer.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            cta.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            cta.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            cta.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -16),

            plansStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            plansStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            plansStack.bottomAnchor.constraint(equalTo: cta.topAnchor, constant: -18),

            topStack.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            topStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            topStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            topStack.bottomAnchor.constraint(lessThanOrEqualTo: plansStack.topAnchor, constant: -14)
        ])
    }

    private func textBlock() -> UIView {
        let title = UILabel()
        title.text = NSLocalizedString("Unlock Unlimited Creativity", comment: "Paywall title")
        title.font = Theme.Font.heading(24, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.textAlignment = .center
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = NSLocalizedString("Everything you need to make forever memories.", comment: "Paywall subtitle")
        subtitle.font = Theme.Font.body(13, weight: 600)
        subtitle.textColor = Theme.Color.textSecondary
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let bullets = UIStackView(arrangedSubviews: SubscriptionPlan.benefits.map(benefitRow))
        bullets.axis = .vertical
        bullets.spacing = 9

        let body = UIStackView(arrangedSubviews: [title, subtitle, bullets])
        body.axis = .vertical
        body.alignment = .fill
        body.spacing = 8
        body.setCustomSpacing(16, after: subtitle)
        body.isLayoutMarginsRelativeArrangement = true
        body.layoutMargins = UIEdgeInsets(top: 16, left: 24, bottom: 0, right: 24)
        return body
    }

    private func populatePlanCards() {
        planCards.forEach { $0.removeFromSuperview() }
        planCards = []
        for plan in plans {
            let card = PlanCardView(plan: plan)
            card.isSelectedPlan = plan.productId == selectedPlan?.productId
            card.addTarget(self, action: #selector(planTapped(_:)), for: .touchUpInside)
            planCards.append(card)
            plansStack.addArrangedSubview(card)
        }
    }

    private func heroView() -> UIView {
        let container = UIView()
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(hex: 0xFBE1E7).cgColor, UIColor(hex: 0xFFF7F0).cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        container.layer.insertSublayer(gradient, at: 0)
        container.translatesAutoresizingMaskIntoConstraints = false
        DispatchQueue.main.async { gradient.frame = container.bounds }

        let deck = fannedPhotoDeck()

        let badge = PaddedLabel()
        badge.text = NSLocalizedString("NEWBORN PRO", comment: "Paywall hero badge")
        badge.horizontalPadding = 14
        badge.font = Theme.Font.heading(11, weight: 700)
        badge.textColor = Theme.Color.accentEnd
        badge.backgroundColor = .white
        badge.layer.cornerRadius = 14
        badge.layer.masksToBounds = true
        badge.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [deck, badge])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            deck.heightAnchor.constraint(equalToConstant: 96),
            badge.heightAnchor.constraint(equalToConstant: 26),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            // Pinned relative to the safe area (not a fixed container height) so the fanned,
            // rotated deck never renders under the status bar / Dynamic Island on any device.
            stack.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        return container
    }

    /// Bundled in the app (Assets.xcassets) rather than fetched over the network — these are
    /// the same real AI-generated illustrations already shipped for onboarding, so the paywall
    /// hero renders instantly and never depends on a Firestore/Storage round trip.
    private func fannedPhotoDeck() -> UIView {
        let specs: [(String, CGSize, CGFloat)] = [
            ("OnboardingThemedPortraits", CGSize(width: 64, height: 82), -6),
            ("OnboardingSleepingBaby", CGSize(width: 70, height: 92), 0),
            ("OnboardingMilestoneAlbum", CGSize(width: 64, height: 82), 6)
        ]
        let cardViews: [UIView] = specs.map { imageName, size, rotation in
            let imageView = UIImageView(image: UIImage(named: imageName))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = UIColor(hex: 0xEDE7FB)
            imageView.layer.cornerRadius = 14
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: size.width).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: size.height).isActive = true

            let shadowWrap = UIView()
            shadowWrap.layer.shadowColor = Theme.Color.textPrimary.cgColor
            shadowWrap.layer.shadowOpacity = 0.22
            shadowWrap.layer.shadowRadius = 10
            shadowWrap.layer.shadowOffset = CGSize(width: 0, height: 6)
            shadowWrap.transform = CGAffineTransform(rotationAngle: rotation * .pi / 180)
            shadowWrap.translatesAutoresizingMaskIntoConstraints = false
            shadowWrap.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: shadowWrap.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: shadowWrap.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: shadowWrap.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: shadowWrap.bottomAnchor)
            ])
            return shadowWrap
        }

        let deck = UIStackView(arrangedSubviews: cardViews)
        deck.axis = .horizontal
        deck.alignment = .center
        deck.spacing = 8
        return deck
    }

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

    private func footerLink(_ title: String) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(Theme.Color.textSecondary, for: .normal)
        button.titleLabel?.font = Theme.Font.body(12, weight: 600)
        return button
    }

    @objc private func planTapped(_ sender: PlanCardView) {
        HapticFeedback.selection()
        selectedPlan = sender.plan
        for card in planCards { card.isSelectedPlan = card.plan.productId == sender.plan.productId }
    }

    @objc private func subscribeTapped() {
        guard let selectedPlan else { return }
        HapticFeedback.light()
        cta.setLoading(true)
        RevenueCatService.purchase(package: selectedPlan.package) { [weak self] result in
            DispatchQueue.main.async {
                self?.cta.setLoading(false)
                switch result {
                case .success:
                    HapticFeedback.success()
                    self?.onDismiss?()
                case .failure(RevenueCatServiceError.userCancelled):
                    break
                case .failure(let error):
                    HapticFeedback.error()
                    self?.presentPurchaseError(error)
                }
            }
        }
    }

    @objc private func closeTapped() {
        onDismiss?()
    }

    @objc private func restoreTapped() {
        HapticFeedback.light()
        RevenueCatService.restore { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let customerInfo):
                    if !customerInfo.entitlements.active.isEmpty {
                        HapticFeedback.success()
                        self?.onDismiss?()
                    } else {
                        self?.presentPurchaseError(RevenueCatServiceError.offeringNotFound, title: NSLocalizedString("Nothing to restore", comment: "Restore purchases error title"))
                    }
                case .failure(let error):
                    self?.presentPurchaseError(error)
                }
            }
        }
    }

    private func presentPurchaseError(_ error: Error, title: String = NSLocalizedString("Something went wrong", comment: "Generic error title")) {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .default))
        present(alert, animated: true)
    }

    @objc private func termsTapped() {
        HapticFeedback.light()
        UIApplication.shared.open(LegalLinks.termsOfUse)
    }

    @objc private func privacyTapped() {
        HapticFeedback.light()
        UIApplication.shared.open(LegalLinks.privacyPolicy)
    }
}
