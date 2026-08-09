import UIKit
import RevenueCat

/// The "single offer" paywall — same design as PaywallViewController (hero, title, benefits,
/// footer, CTA), but sells exactly one subscription tier with no package-selection stackView, in
/// place of PaywallViewController's plansStack. Which tier is intentionally driven by Remote
/// Config's "introPackage" (a RevenueCat product id — weekly, monthly, or yearly, whichever is
/// currently the intro offer), see RemoteConfigService. Shown right after onboarding and, on
/// later sessions, right after splash — gated by "frun" — see AppCoordinator.
///
/// Deliberately a separate, self-contained file rather than a refactor of PaywallViewController:
/// duplicating the shared visual builders (hero/text/footer) keeps the already-shipping
/// subscription paywall untouched while this screen iterates independently.
final class SingleOfferPaywallViewController: UIViewController {
    var onDismiss: (() -> Void)?

    /// Every paywall in the app is presented modally, full screen, with a self-dismissing close
    /// button — mirrors PaywallViewController.presented().
    static func presented() -> SingleOfferPaywallViewController {
        let paywall = SingleOfferPaywallViewController()
        paywall.modalPresentationStyle = .fullScreen
        paywall.onDismiss = { [weak paywall] in
            paywall?.dismiss(animated: true)
        }
        return paywall
    }

    private let spinner = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    private let contentContainer = UIView()
    private var planInfoView: SinglePlanInfoView?
    private var planInfoContainer: UIView!
    private var plan: SubscriptionPlan?
    private let cta = GradientPillButton(title: NSLocalizedString("Continue", comment: "Paywall CTA button"), icon: nil)

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
            guard let resolved = Self.resolvePlan(from: offering) else {
                errorLabel.text = NSLocalizedString("Couldn't load plans. Check your connection and try again.", comment: "Paywall load error")
                errorLabel.isHidden = false
                return
            }
            plan = resolved
            let info = SinglePlanInfoView(plan: resolved)
            info.translatesAutoresizingMaskIntoConstraints = false
            planInfoContainer.addSubview(info)
            NSLayoutConstraint.activate([
                info.topAnchor.constraint(equalTo: planInfoContainer.topAnchor),
                info.leadingAnchor.constraint(equalTo: planInfoContainer.leadingAnchor),
                info.trailingAnchor.constraint(equalTo: planInfoContainer.trailingAnchor),
                info.bottomAnchor.constraint(equalTo: planInfoContainer.bottomAnchor)
            ])
            planInfoView = info
            contentContainer.isHidden = false
        case .failure(let error):
            // Real offline/error state — never an infinite spinner (Stability Gate rule).
            errorLabel.text = NSLocalizedString("Couldn't load plans. Check your connection and try again.", comment: "Paywall load error")
            errorLabel.isHidden = false
            print("RevenueCatService.fetchOffering failed: \(error)")
        }
    }

    /// Matches Remote Config's "introPackage" product id against the offering's real packages.
    /// Falls back to the yearly (or first available) subscription package if the config value is
    /// unset or doesn't match anything real — this screen should never end up with nothing to
    /// sell just because a remote value was misconfigured.
    private static func resolvePlan(from offering: RevenueCat.Offering) -> SubscriptionPlan? {
        let displayOrder: [PackageType] = [.weekly, .monthly, .annual]
        let subscriptionPackages = offering.availablePackages.filter { displayOrder.contains($0.packageType) }
        if let productId = RemoteConfigService.introPackageProductId,
           let match = subscriptionPackages.first(where: { $0.storeProduct.productIdentifier == productId }) {
            return SubscriptionPlan(package: match)
        }
        let fallback = subscriptionPackages.first(where: { $0.packageType == .annual }) ?? subscriptionPackages.first
        return fallback.map(SubscriptionPlan.init(package:))
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

    /// Same bottom-up anchoring as PaywallViewController: footer -> CTA -> plan info, so those
    /// stay pinned to the bottom regardless of how tall the top content ends up being.
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

        planInfoContainer = UIView()
        planInfoContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(planInfoContainer)

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

            planInfoContainer.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            planInfoContainer.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            planInfoContainer.bottomAnchor.constraint(equalTo: cta.topAnchor, constant: -18),

            topStack.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            topStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            topStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            topStack.bottomAnchor.constraint(lessThanOrEqualTo: planInfoContainer.topAnchor, constant: -14)
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

        // The benefit bullets moved into SinglePlanInfoView — grouped with the price instead of
        // sitting up here disconnected from what they're describing.
        let body = UIStackView(arrangedSubviews: [title, subtitle])
        body.axis = .vertical
        body.alignment = .fill
        body.spacing = 8
        body.isLayoutMarginsRelativeArrangement = true
        body.layoutMargins = UIEdgeInsets(top: 16, left: 24, bottom: 0, right: 24)
        return body
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
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            // Bigger than PaywallViewController's hero on purpose — this screen has no
            // package-selection stack competing for vertical space, so the deck gets to be the
            // dominant visual instead of a compact strip above the title.
            deck.heightAnchor.constraint(equalToConstant: 130),
            badge.heightAnchor.constraint(equalToConstant: 30),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        return container
    }

    private func fannedPhotoDeck() -> UIView {
        let specs: [(String, CGSize, CGFloat)] = [
            ("OnboardingThemedPortraits", CGSize(width: 86, height: 110), -6),
            ("OnboardingSleepingBaby", CGSize(width: 94, height: 124), 0),
            ("OnboardingMilestoneAlbum", CGSize(width: 86, height: 110), 6)
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

    private func footerLink(_ title: String) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(Theme.Color.textSecondary, for: .normal)
        button.titleLabel?.font = Theme.Font.body(12, weight: 600)
        return button
    }

    @objc private func subscribeTapped() {
        guard let plan else { return }
        HapticFeedback.light()
        cta.setLoading(true)
        RevenueCatService.purchase(package: plan.package) { [weak self] result in
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
