import UIKit

/// The pink/rose gradient pill CTA used across onboarding, paywall, and the coin sheet.
final class GradientPillButton: UIControl {
    private let gradientLayer = CAGradientLayer.accentPill()
    private let titleLabel = UILabel()
    private let iconView = UIImageView()
    private let contentStack = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .medium)

    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    init(title: String, icon: UIImage? = UIImage(systemName: "arrow.forward"), height: CGFloat = 56) {
        super.init(frame: .zero)
        self.title = title
        setUp(icon: icon, height: height)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUp(icon: UIImage?, height: CGFloat) {
        layer.insertSublayer(gradientLayer, at: 0)
        layer.masksToBounds = true
        layer.shadowColor = Theme.Color.accentEnd.cgColor
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 10)

        titleLabel.text = title
        titleLabel.font = Theme.Font.heading(17, weight: 700)
        titleLabel.textColor = .white
        titleLabel.isUserInteractionEnabled = false

        iconView.image = icon
        iconView.tintColor = .white
        iconView.isUserInteractionEnabled = false
        iconView.contentMode = .scaleAspectFit

        contentStack.addArrangedSubview(titleLabel)
        if icon != nil { contentStack.addArrangedSubview(iconView) }
        contentStack.axis = .horizontal
        contentStack.spacing = 8
        contentStack.alignment = .center
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)

        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: height)
        ])

        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    /// Swaps the title/icon for a spinner and disables interaction — used while an in-flight
    /// purchase call is running, so the CTA never looks tappable-but-inert.
    func setLoading(_ loading: Bool) {
        isEnabled = !loading
        contentStack.alpha = loading ? 0 : 1
        if loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        // Neither CALayer.cornerRadius nor UIBezierPath(roundedRect:cornerRadius:) clamps a
        // radius that exceeds half the shorter side — both self-intersect into a cusped,
        // pointed shape instead of a clean semicircular cap. Theme.Shape.pillRadius (100) is
        // deliberately oversized so this always resolves to a true capsule regardless of the
        // button's actual height, rather than depending on a hand-tuned constant matching it.
        let radius = min(bounds.width, bounds.height) / 2
        layer.cornerRadius = radius
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
    }

    @objc private func touchDown() {
        UIView.animate(withDuration: 0.12) { self.alpha = 0.85; self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98) }
    }

    @objc private func touchUp() {
        UIView.animate(withDuration: 0.12) { self.alpha = 1; self.transform = .identity }
    }
}
