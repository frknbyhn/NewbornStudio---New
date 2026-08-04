import UIKit
import RevenueCat

final class PaywallViewController: UIViewController {
    var onDismiss: (() -> Void)?

    private let scrollView = UIScrollView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    private var plansStack: UIStackView!
    private var planCards: [PlanCardView] = []
    private var plans: [SubscriptionPlan] = []
    private var selectedPlan: SubscriptionPlan?
    private let billedCaption = UILabel()
    private let cta = GradientPillButton(title: "Subscribe Now", icon: nil)
    private var heroImageViews: [UIImageView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpScrollContent()
        setUpCloseButton()
        setUpLoadingState()
        loadOffering()
        loadHeroPreviews()
    }

    private func loadHeroPreviews() {
        ThemeService.fetchThemes(categoryId: nil, limit: 3) { [weak self] result in
            guard let self, case .success(let cards) = result else { return }
            for (imageView, card) in zip(self.heroImageViews, cards) {
                guard let url = card.previewImageUrl else { continue }
                RemoteImageLoader.load(url) { image in
                    guard let image else { return }
                    UIView.transition(with: imageView, duration: 0.25, options: .transitionCrossDissolve) {
                        imageView.image = image
                    }
                }
            }
        }
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
        scrollView.isHidden = true
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
            scrollView.isHidden = false
        case .failure(let error):
            // Real offline/error state — never an infinite spinner (Stability Gate rule).
            errorLabel.text = "Couldn't load plans. Check your connection and try again."
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

        plansStack = UIStackView()
        plansStack.axis = .horizontal
        plansStack.spacing = 10
        plansStack.distribution = .fillEqually
        body.addArrangedSubview(plansStack)
        body.setCustomSpacing(24, after: plansStack)

        cta.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
        body.addArrangedSubview(cta)

        billedCaption.font = Theme.Font.body(11, weight: 600)
        billedCaption.textColor = UIColor(hex: 0xB4A6A2)
        billedCaption.textAlignment = .center
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
        updateBilledCaption()
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
        badge.text = "NEWBORN PRO"
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
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            deck.heightAnchor.constraint(equalToConstant: 112),
            badge.heightAnchor.constraint(equalToConstant: 28),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            // Pinned relative to the safe area (not a fixed container height) so the fanned,
            // rotated deck never renders under the status bar / Dynamic Island on any device.
            stack.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18)
        ])
        return container
    }

    /// Three fanned, rotated preview cards — matches the design mockup's photo-stack hero,
    /// filled with real generated portraits (fetched async) rather than a static illustration.
    private func fannedPhotoDeck() -> UIView {
        let sizes: [(CGSize, CGFloat)] = [
            (CGSize(width: 74, height: 96), -6),
            (CGSize(width: 82, height: 112), 0),
            (CGSize(width: 74, height: 96), 6)
        ]
        heroImageViews = []
        let cardViews: [UIView] = sizes.map { size, rotation in
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = UIColor(hex: 0xEDE7FB)
            imageView.layer.cornerRadius = 14
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: size.width).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: size.height).isActive = true
            heroImageViews.append(imageView)

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
        guard let selectedPlan else { return }
        let periodWord = selectedPlan.title == "Weekly" ? "weekly" : selectedPlan.title == "Monthly" ? "monthly" : "yearly"
        billedCaption.text = "Billed \(selectedPlan.priceLabel) \(periodWord) · Cancel anytime"
    }

    @objc private func planTapped(_ sender: PlanCardView) {
        HapticFeedback.selection()
        selectedPlan = sender.plan
        for card in planCards { card.isSelectedPlan = card.plan.productId == sender.plan.productId }
        updateBilledCaption()
    }

    @objc private func subscribeTapped() {
        guard let selectedPlan else { return }
        HapticFeedback.light()
        cta.isEnabled = false
        RevenueCatService.purchase(package: selectedPlan.package) { [weak self] result in
            DispatchQueue.main.async {
                self?.cta.isEnabled = true
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
                        self?.presentPurchaseError(RevenueCatServiceError.offeringNotFound, title: "Nothing to restore")
                    }
                case .failure(let error):
                    self?.presentPurchaseError(error)
                }
            }
        }
    }

    private func presentPurchaseError(_ error: Error, title: String = "Something went wrong") {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
