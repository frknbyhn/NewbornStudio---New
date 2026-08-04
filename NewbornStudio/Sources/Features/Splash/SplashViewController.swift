import UIKit

final class SplashViewController: UIViewController {
    var onFinished: (() -> Void)?

    private let logoBadge = UIView()
    private let logoIcon = UIImageView(image: UIImage(systemName: "figure.child"))
    private let ring = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let dotsStack = UIStackView()
    private var dotViews: [UIView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    private func setUpViews() {
        ring.layer.cornerRadius = 46
        ring.layer.borderWidth = 2
        ring.layer.borderColor = Theme.Color.accentEnd.withAlphaComponent(0.25).cgColor
        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.alpha = 0
        ring.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)

        logoBadge.backgroundColor = Theme.Color.accentEnd
        logoBadge.layer.cornerRadius = 30
        logoBadge.translatesAutoresizingMaskIntoConstraints = false
        logoBadge.alpha = 0
        logoBadge.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        logoBadge.layer.shadowColor = Theme.Color.accentEnd.cgColor
        logoBadge.layer.shadowOpacity = 0.35
        logoBadge.layer.shadowRadius = 18
        logoBadge.layer.shadowOffset = CGSize(width: 0, height: 8)

        logoIcon.tintColor = .white
        logoIcon.contentMode = .scaleAspectFit
        logoIcon.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Newborn Studio"
        titleLabel.font = Theme.Font.heading(24, weight: 700)
        titleLabel.textColor = Theme.Color.textPrimaryAlt
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 10)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.text = "AI baby photo studio"
        subtitleLabel.font = Theme.Font.body(14, weight: 600)
        subtitleLabel.textColor = Theme.Color.textSecondary
        subtitleLabel.alpha = 0
        subtitleLabel.transform = CGAffineTransform(translationX: 0, y: 10)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        dotsStack.axis = .horizontal
        dotsStack.spacing = 7
        dotsStack.alpha = 0
        dotsStack.translatesAutoresizingMaskIntoConstraints = false
        for _ in 0..<3 {
            let dot = UIView()
            dot.backgroundColor = Theme.Color.accentEnd
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
            dotsStack.addArrangedSubview(dot)
            dotViews.append(dot)
        }

        view.addSubview(ring)
        view.addSubview(logoBadge)
        logoBadge.addSubview(logoIcon)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(dotsStack)

        NSLayoutConstraint.activate([
            logoBadge.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoBadge.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            logoBadge.widthAnchor.constraint(equalToConstant: 92),
            logoBadge.heightAnchor.constraint(equalToConstant: 92),

            ring.centerXAnchor.constraint(equalTo: logoBadge.centerXAnchor),
            ring.centerYAnchor.constraint(equalTo: logoBadge.centerYAnchor),
            ring.widthAnchor.constraint(equalToConstant: 92),
            ring.heightAnchor.constraint(equalToConstant: 92),

            logoIcon.centerXAnchor.constraint(equalTo: logoBadge.centerXAnchor),
            logoIcon.centerYAnchor.constraint(equalTo: logoBadge.centerYAnchor),
            logoIcon.widthAnchor.constraint(equalToConstant: 44),
            logoIcon.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: logoBadge.bottomAnchor, constant: 22),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            dotsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 26),
            dotsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func animateIn() {
        UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.62, initialSpringVelocity: 0.4, options: [.curveEaseOut]) {
            self.logoBadge.alpha = 1
            self.logoBadge.transform = .identity
        }

        UIView.animate(withDuration: 0.6, delay: 0.1, options: [.curveEaseOut]) {
            self.ring.alpha = 1
            self.ring.transform = .identity
        } completion: { _ in
            self.pulseRing()
        }

        UIView.animate(withDuration: 0.4, delay: 0.3, options: [.curveEaseOut]) {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        }

        UIView.animate(withDuration: 0.4, delay: 0.4, options: [.curveEaseOut]) {
            self.subtitleLabel.alpha = 1
            self.subtitleLabel.transform = .identity
        }

        UIView.animate(withDuration: 0.3, delay: 0.55, options: []) {
            self.dotsStack.alpha = 1
        } completion: { _ in
            self.animateDots()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.onFinished?()
        }
    }

    private func pulseRing() {
        UIView.animate(withDuration: 1.1, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.ring.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
            self.ring.alpha = 0.4
        }
    }

    private func animateDots() {
        for (index, dot) in dotViews.enumerated() {
            UIView.animate(withDuration: 0.5, delay: Double(index) * 0.15, options: [.repeat, .autoreverse, .curveEaseInOut]) {
                dot.transform = CGAffineTransform(translationX: 0, y: -6)
                dot.alpha = 0.4
            }
        }
    }
}
