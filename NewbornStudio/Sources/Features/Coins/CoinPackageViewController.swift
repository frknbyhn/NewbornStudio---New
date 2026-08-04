import UIKit

final class CoinPackageViewController: UIViewController {
    private var rows: [CoinPackageRow] = []
    private var selected: CoinPackage = CoinPackage.all.first(where: \.isPopular) ?? CoinPackage.all[0]
    private let ctaButton = GradientPillButton(title: "", icon: UIImage(systemName: "lock.fill"))

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpScroll()
        setUpBottomBar()
        updateCTA()
    }

    private func setUpScroll() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 20
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -140),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        content.addArrangedSubview(heroView())

        let list = UIStackView(arrangedSubviews: CoinPackage.all.map { pkg in
            let row = CoinPackageRow(package: pkg)
            row.isSelectedPackage = pkg.productId == selected.productId
            row.addTarget(self, action: #selector(rowTapped(_:)), for: .touchUpInside)
            rows.append(row)
            return row
        })
        list.axis = .vertical
        list.spacing = 12
        list.isLayoutMarginsRelativeArrangement = true
        list.layoutMargins = UIEdgeInsets(top: 0, left: 24, bottom: 24, right: 24)
        content.addArrangedSubview(list)
    }

    private func heroView() -> UIView {
        let container = UIView()
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(hex: 0xFFF3D9).cgColor, UIColor(hex: 0xFFF7F0).cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        container.layer.insertSublayer(gradient, at: 0)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 190).isActive = true
        DispatchQueue.main.async { gradient.frame = container.bounds }

        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        back.tintColor = UIColor(hex: 0x8A5E12)
        back.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        back.layer.cornerRadius = 12
        back.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        back.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "banknote.fill"))
        icon.tintColor = Theme.Color.coin
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = "Top up your coins"
        title.font = Theme.Font.heading(24, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Spend coins to generate any portrait — no subscription needed."
        subtitle.font = Theme.Font.body(13, weight: 600)
        subtitle.textColor = UIColor(hex: 0xB08A3E)
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [icon, title, subtitle])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        container.addSubview(back)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 40),
            icon.heightAnchor.constraint(equalToConstant: 40),
            back.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: 14),
            back.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            back.widthAnchor.constraint(equalToConstant: 36),
            back.heightAnchor.constraint(equalToConstant: 36),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18)
        ])
        return container
    }

    private func setUpBottomBar() {
        let bar = UIView()
        bar.backgroundColor = Theme.Color.backgroundCream
        bar.translatesAutoresizingMaskIntoConstraints = false

        ctaButton.addTarget(self, action: #selector(purchaseTapped), for: .touchUpInside)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false

        let secureLabel = UILabel()
        secureLabel.text = "🔒 Secure payment · Apple Pay · Google Pay"
        secureLabel.font = Theme.Font.body(11.5, weight: 600)
        secureLabel.textColor = UIColor(hex: 0xB4A6A2)
        secureLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [ctaButton, secureLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 24, bottom: 20, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(stack)
        view.addSubview(bar)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: bar.topAnchor),
            stack.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bar.safeAreaLayoutGuide.bottomAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateCTA() {
        ctaButton.title = "Buy \(selected.credits) coins · \(selected.priceLabel)"
    }

    @objc private func rowTapped(_ sender: CoinPackageRow) {
        HapticFeedback.selection()
        selected = sender.package
        for row in rows { row.isSelectedPackage = row.package.productId == selected.productId }
        updateCTA()
    }

    @objc private func purchaseTapped() {
        // RevenueCat consumable purchase flow wires in here in Phase 7.
        HapticFeedback.success()
    }

    @objc private func backTapped() {
        if let nav = navigationController, nav.viewControllers.first !== self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
