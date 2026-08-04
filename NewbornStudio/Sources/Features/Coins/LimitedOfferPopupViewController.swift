import UIKit
import RevenueCat

/// Themed modal for the one-time "Limited Time Offer" coin pack — see LimitedOfferService for
/// the persisted 6-hour deadline / once-per-session / post-expiry rules this presents.
final class LimitedOfferPopupViewController: UIViewController {
    private let state: LimitedOfferService.PopupState
    private let card = UIView()
    private let countdownLabel = UILabel()
    private let priceLabel = UILabel()
    private let cta = GradientPillButton(title: "Claim Offer", icon: nil)
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var countdownTimer: Timer?
    private var deadline: Date?
    private var limitedPackage: CoinPackage?

    init(state: LimitedOfferService.PopupState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        if case .active(let remaining) = state {
            deadline = Date().addingTimeInterval(remaining)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.55)

        let dimTap = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        dimTap.delegate = self
        view.addGestureRecognizer(dimTap)

        setUpCard()
        switch state {
        case .active:
            populateActiveState()
            startCountdown()
            loadPackage()
        case .lastChance:
            populateLastChanceState()
            loadPackage()
        }
    }

    deinit {
        countdownTimer?.invalidate()
    }

    private func setUpCard() {
        card.backgroundColor = Theme.Color.backgroundCream
        card.layer.cornerRadius = 28
        card.translatesAutoresizingMaskIntoConstraints = false
        card.isUserInteractionEnabled = true
        view.addSubview(card)
        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28)
        ])
    }

    private func populateActiveState() {
        let badgeIcon = medallion(symbol: "gift.fill", diameter: 76)

        let badge = PaddedLabel()
        badge.text = "LIMITED TIME OFFER"
        badge.horizontalPadding = 12
        badge.font = Theme.Font.heading(11, weight: 700)
        badge.textColor = Theme.Color.accentEnd
        badge.backgroundColor = Theme.Color.purpleBackground
        badge.layer.cornerRadius = 12
        badge.layer.masksToBounds = true
        badge.textAlignment = .center

        let title = UILabel()
        title.text = "A Special Offer, Just for You"
        title.font = Theme.Font.heading(21, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.textAlignment = .center
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = "Grab this bundle before the timer runs out."
        subtitle.font = Theme.Font.body(13.5, weight: 600)
        subtitle.textColor = Theme.Color.textSecondary
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        countdownLabel.font = Theme.Font.heading(28, weight: 700)
        countdownLabel.textColor = Theme.Color.accentEnd
        countdownLabel.textAlignment = .center
        countdownLabel.text = "--:--:--"

        let countdownWrap = UIView()
        countdownWrap.backgroundColor = .white
        countdownWrap.layer.cornerRadius = 16
        countdownWrap.translatesAutoresizingMaskIntoConstraints = false
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        countdownWrap.addSubview(countdownLabel)
        NSLayoutConstraint.activate([
            countdownLabel.topAnchor.constraint(equalTo: countdownWrap.topAnchor, constant: 12),
            countdownLabel.bottomAnchor.constraint(equalTo: countdownWrap.bottomAnchor, constant: -12),
            countdownLabel.centerXAnchor.constraint(equalTo: countdownWrap.centerXAnchor)
        ])

        priceLabel.font = Theme.Font.heading(15, weight: 700)
        priceLabel.textColor = Theme.Color.textSecondaryAlt
        priceLabel.textAlignment = .center
        priceLabel.text = " "

        spinner.color = Theme.Color.accentEnd
        spinner.hidesWhenStopped = true
        spinner.startAnimating()

        cta.isHidden = true
        cta.addTarget(self, action: #selector(claimTapped), for: .touchUpInside)

        let footer = UILabel()
        footer.text = "One-time offer — expires when the timer ends."
        footer.font = Theme.Font.body(11, weight: 600)
        footer.textColor = UIColor(hex: 0xB4A6A2)
        footer.textAlignment = .center
        footer.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [badgeIcon, badge, title, subtitle, countdownWrap, priceLabel, spinner, cta, footer])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(18, after: badgeIcon)
        stack.setCustomSpacing(6, after: title)
        stack.setCustomSpacing(18, after: subtitle)
        stack.setCustomSpacing(16, after: countdownWrap)
        stack.setCustomSpacing(20, after: priceLabel)
        stack.setCustomSpacing(10, after: cta)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 54, left: 26, bottom: 26, right: 26)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            cta.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -52),
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
    }

    /// The timer already hit zero, but this is still purchasable — one final, still-live shot
    /// at the deal. Closing this screen (X or dim tap) is what permanently retires the offer;
    /// LimitedOfferService has already recorded that before this view even appears.
    private func populateLastChanceState() {
        let badgeIcon = medallion(symbol: "flame.fill", diameter: 76)

        let badge = PaddedLabel()
        badge.text = "LAST CHANCE"
        badge.horizontalPadding = 12
        badge.font = Theme.Font.heading(11, weight: 700)
        badge.textColor = Theme.Color.accentEnd
        badge.backgroundColor = Theme.Color.purpleBackground
        badge.layer.cornerRadius = 12
        badge.layer.masksToBounds = true
        badge.textAlignment = .center

        let title = UILabel()
        title.text = "Your Final Chance!"
        title.font = Theme.Font.heading(21, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.textAlignment = .center
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = "This exclusive bundle won't be offered again. Grab it now, or it's gone for good."
        subtitle.font = Theme.Font.body(13.5, weight: 600)
        subtitle.textColor = Theme.Color.textSecondary
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        priceLabel.font = Theme.Font.heading(15, weight: 700)
        priceLabel.textColor = Theme.Color.textSecondaryAlt
        priceLabel.textAlignment = .center
        priceLabel.text = " "

        spinner.color = Theme.Color.accentEnd
        spinner.hidesWhenStopped = true
        spinner.startAnimating()

        cta.isHidden = true
        cta.addTarget(self, action: #selector(claimTapped), for: .touchUpInside)

        let footer = UILabel()
        footer.text = "Close this and it's gone for good."
        footer.font = Theme.Font.body(11, weight: 600)
        footer.textColor = UIColor(hex: 0xB4A6A2)
        footer.textAlignment = .center
        footer.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [badgeIcon, badge, title, subtitle, priceLabel, spinner, cta, footer])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(18, after: badgeIcon)
        stack.setCustomSpacing(6, after: title)
        stack.setCustomSpacing(20, after: subtitle)
        stack.setCustomSpacing(20, after: priceLabel)
        stack.setCustomSpacing(10, after: cta)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 54, left: 26, bottom: 26, right: 26)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            cta.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -52),
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
    }

    private func medallion(symbol: String, diameter: CGFloat, tint: UIColor = .white, background: UIColor? = nil) -> UIView {
        let wrap = UIView()
        if let background {
            wrap.backgroundColor = background
        } else {
            let gradient = CAGradientLayer.accentPill()
            gradient.cornerRadius = diameter / 2
            wrap.layer.insertSublayer(gradient, at: 0)
            DispatchQueue.main.async { gradient.frame = CGRect(x: 0, y: 0, width: diameter, height: diameter) }
        }
        wrap.layer.cornerRadius = diameter / 2
        wrap.layer.shadowColor = Theme.Color.accentEnd.cgColor
        wrap.layer.shadowOpacity = 0.35
        wrap.layer.shadowRadius = 14
        wrap.layer.shadowOffset = CGSize(width: 0, height: 8)
        wrap.translatesAutoresizingMaskIntoConstraints = false
        wrap.widthAnchor.constraint(equalToConstant: diameter).isActive = true
        wrap.heightAnchor.constraint(equalToConstant: diameter).isActive = true

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = background == nil ? .white : tint
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: wrap.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: diameter * 0.44),
            icon.heightAnchor.constraint(equalToConstant: diameter * 0.44)
        ])
        return wrap
    }

    private func loadPackage() {
        RevenueCatService.fetchOffering { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.spinner.stopAnimating()
                guard case .success(let offering) = result,
                      let package = offering.availablePackages.first(where: { $0.identifier == "limited" }) else {
                    self.priceLabel.text = "Offer unavailable right now"
                    return
                }
                let coinPackage = CoinPackage(package: package)
                self.limitedPackage = coinPackage
                self.priceLabel.text = "\(coinPackage.credits) coins · \(coinPackage.priceLabel)"
                self.cta.title = "Claim \(coinPackage.credits) Coins"
                self.cta.isHidden = false
            }
        }
    }

    private func startCountdown() {
        updateCountdownLabel()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateCountdownLabel()
        }
    }

    private func updateCountdownLabel() {
        guard let deadline else { return }
        let remaining = max(0, deadline.timeIntervalSinceNow)
        if remaining <= 0 {
            countdownTimer?.invalidate()
            dismiss(animated: true)
            return
        }
        let total = Int(remaining)
        countdownLabel.text = String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    @objc private func claimTapped() {
        guard let limitedPackage else { return }
        HapticFeedback.light()
        cta.setLoading(true)
        RevenueCatService.purchase(package: limitedPackage.package) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.cta.setLoading(false)
                switch result {
                case .success:
                    HapticFeedback.success()
                    LimitedOfferService.markPurchased()
                    self.dismiss(animated: true)
                case .failure(RevenueCatServiceError.userCancelled):
                    break
                case .failure(let error):
                    HapticFeedback.error()
                    let alert = UIAlertController(title: "Purchase failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    @objc private func dismissTapped() {
        countdownTimer?.invalidate()
        dismiss(animated: true)
    }
}

extension LimitedOfferPopupViewController: UIGestureRecognizerDelegate {
    /// Lets the dim background dismiss on tap without swallowing taps meant for the card itself.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !card.frame.contains(touch.location(in: view))
    }
}
