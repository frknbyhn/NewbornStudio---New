import UIKit
import RevenueCat

final class CoinPackageViewController: UIViewController {
    private var rows: [CoinPackageRow] = []
    private var packages: [CoinPackage] = []
    private var selected: CoinPackage?
    private let ctaButton = GradientPillButton(title: "", icon: UIImage(systemName: "lock.fill"))
    private var listStack: UIStackView!
    private let spinner = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    private let scroll = UIScrollView()
    private let bottomBar = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpScroll()
        setUpBottomBar()
        setUpLoadingState()
        loadOffering()
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
        scroll.isHidden = true
        bottomBar.isHidden = true
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
            let displayOrder = ["small", "limited", "medium", "big"]
            packages = offering.availablePackages
                .filter { displayOrder.contains($0.identifier) }
                .sorted { displayOrder.firstIndex(of: $0.identifier)! < displayOrder.firstIndex(of: $1.identifier)! }
                .map(CoinPackage.init(package:))
            selected = packages.first(where: \.isPopular) ?? packages.first
            populateRows()
            updateCTA()
            scroll.isHidden = false
            bottomBar.isHidden = false
        case .failure(let error):
            errorLabel.text = "Couldn't load coin packages. Check your connection and try again."
            errorLabel.isHidden = false
            print("RevenueCatService.fetchOffering failed: \(error)")
        }
    }

    private func setUpScroll() {
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

        listStack = UIStackView()
        listStack.axis = .vertical
        listStack.spacing = 12
        listStack.isLayoutMarginsRelativeArrangement = true
        listStack.layoutMargins = UIEdgeInsets(top: 0, left: 24, bottom: 24, right: 24)
        content.addArrangedSubview(listStack)
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
        bottomBar.backgroundColor = Theme.Color.backgroundCream
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        ctaButton.addTarget(self, action: #selector(purchaseTapped), for: .touchUpInside)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false

        let lockIcon = UIImageView(image: UIImage(systemName: "lock.fill"))
        lockIcon.tintColor = UIColor(hex: 0xB4A6A2)
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.widthAnchor.constraint(equalToConstant: 12).isActive = true
        lockIcon.heightAnchor.constraint(equalToConstant: 12).isActive = true

        let secureLabel = UILabel()
        secureLabel.text = "Secure payment · Apple Pay · Google Pay"
        secureLabel.font = Theme.Font.body(11.5, weight: 600)
        secureLabel.textColor = UIColor(hex: 0xB4A6A2)

        let secureRow = UIStackView(arrangedSubviews: [lockIcon, secureLabel])
        secureRow.axis = .horizontal
        secureRow.spacing = 5
        secureRow.alignment = .center

        let secureContainer = UIView()
        secureRow.translatesAutoresizingMaskIntoConstraints = false
        secureContainer.addSubview(secureRow)
        NSLayoutConstraint.activate([
            secureRow.centerXAnchor.constraint(equalTo: secureContainer.centerXAnchor),
            secureRow.topAnchor.constraint(equalTo: secureContainer.topAnchor),
            secureRow.bottomAnchor.constraint(equalTo: secureContainer.bottomAnchor)
        ])

        let stack = UIStackView(arrangedSubviews: [ctaButton, secureContainer])
        stack.axis = .vertical
        stack.spacing = 10
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 24, bottom: 20, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(stack)
        view.addSubview(bottomBar)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            stack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomBar.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateCTA() {
        guard let selected else { return }
        ctaButton.title = "Buy \(selected.credits) coins · \(selected.priceLabel)"
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
        ctaButton.isEnabled = false
        RevenueCatService.purchase(package: selected.package) { [weak self] result in
            DispatchQueue.main.async {
                self?.ctaButton.isEnabled = true
                switch result {
                case .success:
                    HapticFeedback.success()
                    self?.backTapped()
                case .failure(RevenueCatServiceError.userCancelled):
                    break
                case .failure(let error):
                    HapticFeedback.error()
                    let alert = UIAlertController(title: "Purchase failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
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
}
