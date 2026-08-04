import UIKit
import StoreKit

final class ProfileViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: 0xF6EFEA)
        setUpList()
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
            row(icon: "square.grid.2x2.fill", tint: Theme.Color.accentEnd, tintBg: UIColor(hex: 0xFCE6EC), title: "My Creations", action: #selector(myCreationsTapped)),
            row(icon: "photo.stack.fill", tint: Theme.Color.purpleAccent, tintBg: Theme.Color.purpleBackground, title: "Saved Milestones", action: #selector(savedMilestonesTapped))
        ]))

        stack.addArrangedSubview(card([
            row(icon: "globe", tint: Theme.Color.success, tintBg: Theme.Color.successBackground, title: "Language", trailingText: "English", action: #selector(languageTapped))
        ]))

        stack.addArrangedSubview(card([
            row(icon: "arrow.counterclockwise", tint: Theme.Color.textSecondaryAlt, tintBg: Theme.Color.backgroundWarm, title: "Restore Purchase", action: #selector(restoreTapped)),
            row(icon: "hand.raised.fill", tint: Theme.Color.textSecondaryAlt, tintBg: Theme.Color.backgroundWarm, title: "Privacy Policy", action: #selector(privacyTapped)),
            row(icon: "doc.text.fill", tint: Theme.Color.textSecondaryAlt, tintBg: Theme.Color.backgroundWarm, title: "Terms of Use", action: #selector(termsTapped)),
            row(icon: "star.fill", tint: Theme.Color.coin, tintBg: Theme.Color.coinBackground, title: "Rate the App", action: #selector(rateTapped))
        ]))

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
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

    /// Home(0) / Milestones(1) / Gallery(2) / Profile(3) — see MainTabBarController.
    @objc private func myCreationsTapped() {
        HapticFeedback.selection()
        tabBarController?.selectedIndex = 2
    }

    @objc private func savedMilestonesTapped() {
        HapticFeedback.selection()
        tabBarController?.selectedIndex = 1
    }

    @objc private func languageTapped() {
        HapticFeedback.light()
        let alert = UIAlertController(title: "Language", message: "English is the only language available right now. More are on the way.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func restoreTapped() {
        HapticFeedback.light()
        RevenueCatService.restore { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let customerInfo):
                    if customerInfo.entitlements.active.isEmpty {
                        self.presentAlert(title: "Nothing to restore", message: "No active purchases were found for this account.")
                    } else {
                        HapticFeedback.success()
                        self.presentAlert(title: "Restored", message: "Your purchases have been restored.")
                    }
                case .failure(let error):
                    HapticFeedback.error()
                    self.presentAlert(title: "Couldn't restore purchases", message: error.localizedDescription)
                }
            }
        }
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

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
