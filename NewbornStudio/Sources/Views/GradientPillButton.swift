import UIKit

/// The pink/rose gradient pill CTA used across onboarding, paywall, and the coin sheet.
final class GradientPillButton: UIControl {
    private let gradientLayer = CAGradientLayer.accentPill()
    private let titleLabel = UILabel()
    private let iconView = UIImageView()

    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    init(title: String, icon: UIImage? = UIImage(systemName: "arrow.forward")) {
        super.init(frame: .zero)
        self.title = title
        setUp(icon: icon)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUp(icon: UIImage?) {
        layer.insertSublayer(gradientLayer, at: 0)
        layer.cornerRadius = Theme.Shape.pillRadius / 2
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

        let stack = UIStackView(arrangedSubviews: icon == nil ? [titleLabel] : [titleLabel, iconView])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 56)
        ])

        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }

    @objc private func touchDown() {
        UIView.animate(withDuration: 0.12) { self.alpha = 0.85; self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98) }
    }

    @objc private func touchUp() {
        UIView.animate(withDuration: 0.12) { self.alpha = 1; self.transform = .identity }
    }
}
