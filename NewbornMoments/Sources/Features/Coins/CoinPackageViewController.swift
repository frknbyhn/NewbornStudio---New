import UIKit
import RevenueCat

final class CoinPackageViewController: UIViewController {
    /// Every paywall in the app is presented modally (never pushed), full screen, with a
    /// self-dismissing close button — this factory is the one place that wiring lives.
    /// Wrapped in its own hidden-bar UINavigationController so backTapped()'s dismiss path
    /// (used when there's no push-navigation ancestor) always applies.
    static func presented() -> UIViewController {
        let nav = UINavigationController(rootViewController: CoinPackageViewController())
        nav.modalPresentationStyle = .fullScreen
        nav.navigationBar.isHidden = true
        return nav
    }

    private var rows: [CoinPackageRow] = []
    private var packages: [CoinPackage] = []
    private var selected: CoinPackage?
    private let ctaButton = GradientPillButton(title: "", icon: UIImage(systemName: "lock.fill")) // set in updateCTA()
    private var listStack: UIStackView!
    private let spinner = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    private let contentContainer = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpContent()
        setUpCloseButton()
        setUpLoadingState()
        loadOffering()
    }

    private func setUpCloseButton() {
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = Theme.Color.textSecondaryAlt
        close.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        close.layer.cornerRadius = 16
        close.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(close)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            close.widthAnchor.constraint(equalToConstant: 32),
            close.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func setUpLoadingState() {
        spinner.color = Theme.Color.coin
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

    private func handleOffering(_ result: Result<Offering, Error>) {
        spinner.stopAnimating()
        switch result {
        case .success(let offering):
            // "limited" is intentionally excluded here — it's sold exclusively through the
            // LimitedOfferPopupViewController popup, not as a row in this list.
            let displayOrder = ["small", "medium", "big"]
            packages = offering.availablePackages
                .filter { displayOrder.contains($0.identifier) }
                .sorted { displayOrder.firstIndex(of: $0.identifier)! < displayOrder.firstIndex(of: $1.identifier)! }
                .map(CoinPackage.init(package:))
            selected = packages.first(where: \.isPopular) ?? packages.first
            populateRows()
            updateCTA()
            contentContainer.isHidden = false
        case .failure(let error):
            errorLabel.text = NSLocalizedString("Couldn't load coin packages. Check your connection and try again.", comment: "Coin package load error")
            errorLabel.isHidden = false
            print("RevenueCatService.fetchOffering failed: \(error)")
        }
    }

    /// Mirrors PaywallViewController's structure: non-scrolling, bottom-anchored
    /// (packages -> Continue -> secure-payment footer pinned to the bottom), hero/title/
    /// subtitle/benefit bullets filling the space above.
    private func setUpContent() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainer)
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let termsLink = footerLink(NSLocalizedString("Terms", comment: "Coin package footer link"))
        (termsLink as? UIButton)?.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)
        let privacyLink = footerLink(NSLocalizedString("Privacy", comment: "Coin package footer link"))
        (privacyLink as? UIButton)?.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)
        let secureRow = UIStackView(arrangedSubviews: [termsLink, privacyLink])
        secureRow.axis = .horizontal
        secureRow.alignment = .center
        secureRow.distribution = .equalSpacing
        secureRow.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(secureRow)

        ctaButton.addTarget(self, action: #selector(purchaseTapped), for: .touchUpInside)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(ctaButton)

        listStack = UIStackView()
        listStack.axis = .vertical
        listStack.spacing = 12
        listStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(listStack)

        let topStack = UIStackView(arrangedSubviews: [heroView(), textBlock()])
        topStack.axis = .vertical
        topStack.alignment = .fill
        topStack.spacing = 16
        topStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(topStack)

        NSLayoutConstraint.activate([
            secureRow.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 40),
            secureRow.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -40),
            secureRow.bottomAnchor.constraint(equalTo: contentContainer.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            ctaButton.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            ctaButton.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            ctaButton.bottomAnchor.constraint(equalTo: secureRow.topAnchor, constant: -12),

            listStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            listStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            listStack.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -18),

            topStack.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            topStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            topStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            topStack.bottomAnchor.constraint(lessThanOrEqualTo: listStack.topAnchor, constant: -14)
        ])
    }

    private func textBlock() -> UIView {
        let title = UILabel()
        title.text = NSLocalizedString("Top up your coins", comment: "Coin package screen title")
        title.font = Theme.Font.heading(22, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = NSLocalizedString("Spend coins to generate any portrait — no subscription needed.", comment: "Coin package screen subtitle")
        subtitle.font = Theme.Font.body(13, weight: 600)
        subtitle.textColor = UIColor(hex: 0xB08A3E)
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let bullets = UIStackView(arrangedSubviews: [
            benefitRow(NSLocalizedString("Use on any theme or your own custom prompt", comment: "Coin package benefit")),
            benefitRow(NSLocalizedString("Credits never expire", comment: "Coin package benefit")),
            benefitRow(NSLocalizedString("No subscription or recurring charge", comment: "Coin package benefit"))
        ])
        bullets.axis = .vertical
        bullets.spacing = 9

        let body = UIStackView(arrangedSubviews: [title, subtitle, bullets])
        body.axis = .vertical
        body.alignment = .fill
        body.spacing = 6
        body.setCustomSpacing(14, after: subtitle)
        body.isLayoutMarginsRelativeArrangement = true
        body.layoutMargins = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        return body
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
        label.font = Theme.Font.body(13, weight: 600)
        label.textColor = Theme.Color.textSecondaryAlt
        label.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [iconBackground, label])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        return row
    }

    private func populateRows() {
        rows.forEach { $0.removeFromSuperview() }
        rows = []
        for pkg in packages {
            let row = CoinPackageRow(package: pkg)
            row.isSelectedPackage = pkg.productId == selected?.productId
            row.addTarget(self, action: #selector(rowTapped(_:)), for: .touchUpInside)
            rows.append(row)
            listStack.addArrangedSubview(row)
        }
    }

    private func heroView() -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false

        let deck = fannedCoinDeck()
        deck.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(deck)

        NSLayoutConstraint.activate([
            deck.heightAnchor.constraint(equalToConstant: 80),
            deck.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            deck.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: 10),
            deck.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }

    /// Three fanned, rotated coin-medallion cards — matches the design mockup's icon-stack hero.
    private func fannedCoinDeck() -> UIView {
        let specs: [(CGSize, CGFloat, String, CGFloat)] = [
            (CGSize(width: 46, height: 58), -8, "dollarsign.circle.fill", 22),
            (CGSize(width: 64, height: 80), 0, "banknote.fill", 30),
            (CGSize(width: 46, height: 58), 8, "dollarsign.circle.fill", 22)
        ]
        let cardViews: [UIView] = specs.map { size, rotation, symbol, iconSize in
            let card = UIView()
            card.backgroundColor = UIColor(hex: 0xFFE4A6)
            card.layer.cornerRadius = 14
            card.translatesAutoresizingMaskIntoConstraints = false
            card.widthAnchor.constraint(equalToConstant: size.width).isActive = true
            card.heightAnchor.constraint(equalToConstant: size.height).isActive = true

            let icon = UIImageView(image: UIImage(systemName: symbol))
            icon.tintColor = Theme.Color.coin
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(icon)
            NSLayoutConstraint.activate([
                icon.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: iconSize),
                icon.heightAnchor.constraint(equalToConstant: iconSize)
            ])

            let shadowWrap = UIView()
            shadowWrap.layer.shadowColor = UIColor(hex: 0xC89628).cgColor
            shadowWrap.layer.shadowOpacity = 0.35
            shadowWrap.layer.shadowRadius = 10
            shadowWrap.layer.shadowOffset = CGSize(width: 0, height: 6)
            shadowWrap.transform = CGAffineTransform(rotationAngle: rotation * .pi / 180)
            shadowWrap.translatesAutoresizingMaskIntoConstraints = false
            shadowWrap.addSubview(card)
            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: shadowWrap.topAnchor),
                card.leadingAnchor.constraint(equalTo: shadowWrap.leadingAnchor),
                card.trailingAnchor.constraint(equalTo: shadowWrap.trailingAnchor),
                card.bottomAnchor.constraint(equalTo: shadowWrap.bottomAnchor)
            ])
            return shadowWrap
        }

        let deck = UIStackView(arrangedSubviews: cardViews)
        deck.axis = .horizontal
        deck.alignment = .bottom
        deck.spacing = 10
        return deck
    }

    private func updateCTA() {
        ctaButton.title = NSLocalizedString("Continue", comment: "Coin package continue button")
    }

    @objc private func rowTapped(_ sender: CoinPackageRow) {
        HapticFeedback.selection()
        selected = sender.package
        for row in rows { row.isSelectedPackage = row.package.productId == selected?.productId }
        updateCTA()
    }

    @objc private func purchaseTapped() {
        guard let selected else { return }
        HapticFeedback.light()
        ctaButton.setLoading(true)
        RevenueCatService.purchase(package: selected.package) { [weak self] result in
            DispatchQueue.main.async {
                self?.ctaButton.setLoading(false)
                switch result {
                case .success:
                    HapticFeedback.success()
                    self?.backTapped()
                case .failure(RevenueCatServiceError.userCancelled):
                    break
                case .failure(let error):
                    HapticFeedback.error()
                    let alert = UIAlertController(title: NSLocalizedString("Purchase failed", comment: "Purchase error title"), message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }

    @objc private func backTapped() {
        if let nav = navigationController, nav.viewControllers.first !== self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func footerLink(_ title: String) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(Theme.Color.textSecondary, for: .normal)
        button.titleLabel?.font = Theme.Font.body(12, weight: 600)
        return button
    }

    @objc private func termsTapped() {
        HapticFeedback.light()
        present(UINavigationController(rootViewController: LegalDocumentViewController(kind: .termsOfUse)), animated: true)
    }

    @objc private func privacyTapped() {
        HapticFeedback.light()
        present(UINavigationController(rootViewController: LegalDocumentViewController(kind: .privacyPolicy)), animated: true)
    }
}
