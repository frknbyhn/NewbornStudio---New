import UIKit
import StoreKit

final class ProfileViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: 0xF6EFEA)
        setUpAvatar()
        setUpList()
    }

    private var avatarBottom: NSLayoutYAxisAnchor!

    private func setUpAvatar() {
        let avatar = UIView()
        avatar.backgroundColor = UIColor(hex: 0xEDE7FB)
        avatar.layer.cornerRadius = 41
        avatar.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "person.fill"))
        icon.tintColor = Theme.Color.purpleAccent
        icon.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(icon)

        let name = UILabel()
        name.text = "Guest"
        name.font = Theme.Font.heading(20, weight: 700)
        name.textColor = Theme.Color.textPrimaryAlt
        name.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [avatar, name])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 14, left: 0, bottom: 0, right: 0)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 82),
            avatar.heightAnchor.constraint(equalToConstant: 82),
            icon.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        avatarBottom = stack.bottomAnchor
    }

    private func setUpList() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 30, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        stack.addArrangedSubview(card([
            row(icon: "square.grid.2x2.fill", tint: Theme.Color.accentEnd, tintBg: UIColor(hex: 0xFCE6EC), title: "My Creations", action: nil),
            row(icon: "photo.stack.fill", tint: Theme.Color.purpleAccent, tintBg: Theme.Color.purpleBackground, title: "Saved Milestones", action: nil)
        ]))

        stack.addArrangedSubview(card([
            row(icon: "globe", tint: Theme.Color.success, tintBg: Theme.Color.successBackground, title: "Language", trailingText: "English", action: nil),
            row(icon: "bell.fill", tint: Theme.Color.coin, tintBg: Theme.Color.coinBackground, title: "Notifications", action: nil)
        ]))

        stack.addArrangedSubview(card([
            row(icon: "arrow.counterclockwise", tint: Theme.Color.textSecondaryAlt, tintBg: Theme.Color.backgroundWarm, title: "Restore Purchase", action: #selector(restoreTapped)),
            row(icon: "hand.raised.fill", tint: Theme.Color.textSecondaryAlt, tintBg: Theme.Color.backgroundWarm, title: "Privacy Policy", action: #selector(privacyTapped)),
            row(icon: "doc.text.fill", tint: Theme.Color.textSecondaryAlt, tintBg: Theme.Color.backgroundWarm, title: "Terms of Use", action: #selector(termsTapped)),
            row(icon: "star.fill", tint: Theme.Color.coin, tintBg: Theme.Color.coinBackground, title: "Rate the App", action: #selector(rateTapped))
        ]))

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: avatarBottom, constant: 6),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])
    }

    private func card(_ rows: [UIView]) -> UIView {
        let container = UIStackView(arrangedSubviews: rows)
        container.axis = .vertical
        container.spacing = 0
        container.backgroundColor = .white
        container.layer.cornerRadius = 20
        container.layer.masksToBounds = true
        for (index, row) in rows.enumerated() where index < rows.count - 1 {
            let divider = UIView()
            divider.backgroundColor = UIColor(hex: 0xF2EAE4)
            divider.translatesAutoresizingMaskIntoConstraints = false
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            row.addSubview(divider)
            NSLayoutConstraint.activate([
                divider.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
                divider.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                divider.bottomAnchor.constraint(equalTo: row.bottomAnchor)
            ])
        }
        return container
    }

    private func row(icon: String, tint: UIColor, tintBg: UIColor, title: String, trailingText: String? = nil, action: Selector?) -> UIView {
        let bg = UIView()
        bg.backgroundColor = tintBg
        bg.layer.cornerRadius = 10
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.widthAnchor.constraint(equalToConstant: 34).isActive = true
        bg.heightAnchor.constraint(equalToConstant: 34).isActive = true

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = tint
        iconView.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: bg.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: bg.centerYAnchor)
        ])

        let label = UILabel()
        label.text = title
        label.font = Theme.Font.body(14.5, weight: 700)
        label.textColor = Theme.Color.textPrimaryAlt

        var arranged: [UIView] = [bg, label, UIView()]
        if let trailingText {
            let trailing = UILabel()
            trailing.text = trailingText
            trailing.font = Theme.Font.body(13, weight: 600)
            trailing.textColor = Theme.Color.textSecondary
            arranged.append(trailing)
        }
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(hex: 0xCBBDB8)
        arranged.append(chevron)

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .horizontal
        stack.spacing = 14
        stack.alignment = .center
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 15, left: 16, bottom: 15, right: 16)

        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: control.topAnchor),
            stack.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: control.bottomAnchor)
        ])
        if let action {
            control.addTarget(self, action: action, for: .touchUpInside)
        }
        return control
    }

    @objc private func restoreTapped() {
        // Wired to Purchases.shared.restorePurchases in Phase 7 (RevenueCat).
        HapticFeedback.light()
    }
    @objc private func privacyTapped() { HapticFeedback.light(); presentLegal(title: "Privacy Policy") }
    @objc private func termsTapped() { HapticFeedback.light(); presentLegal(title: "Terms of Use") }
    @objc private func rateTapped() {
        HapticFeedback.light()
        if let scene = view.window?.windowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func presentLegal(title: String) {
        let legal = LegalDocumentViewController(title: title)
        present(UINavigationController(rootViewController: legal), animated: true)
    }
}
