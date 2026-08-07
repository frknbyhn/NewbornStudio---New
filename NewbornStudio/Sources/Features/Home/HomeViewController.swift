import UIKit
import FirebaseFunctions

final class HomeViewController: UIViewController {
    private let coinLabel = UILabel()
    private var collectionView: UICollectionView!
    private var categories: [ThemeCategory] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpHeader()
        #if DEBUG
        setUpTestNotificationButton()
        #endif
        setUpGrid()
        loadCategories()
        // Purchase screens (coin pack, limited offer, subscription) post this right after a
        // purchase is granted — more reliable than counting on viewWillAppear/viewDidAppear
        // firing again once they dismiss, which isn't guaranteed here (see the notification's
        // own doc comment in RevenueCatService.swift for why).
        NotificationCenter.default.addObserver(self, selector: #selector(handleCreditsDidChange), name: .creditsDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentLimitedOfferIfNeeded()
        refreshCoinBalance()
    }

    @objc private func handleCreditsDidChange() {
        refreshCoinBalance()
    }

    private func refreshCoinBalance() {
        CreditsService.fetchStatus { [weak self] result in
            guard let self, case .success(let status) = result else { return }
            DispatchQueue.main.async {
                self.coinLabel.text = "\(status.totalCredits)"
            }
        }
    }

    private func presentLimitedOfferIfNeeded() {
        guard let state = LimitedOfferService.popupStateForThisLaunch() else { return }
        present(LimitedOfferPopupViewController(state: state), animated: true)
    }

    private func loadCategories() {
        ThemeService.fetchCategories { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let categories):
                self.categories = categories
                self.collectionView.reloadData()
                self.openDebugCategoryIfNeeded()
            case .failure(let error):
                print("ThemeService.fetchCategories failed: \(error)")
            }
        }
    }

    private func openDebugCategoryIfNeeded() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["NS_DEBUG_OPEN_CUSTOM_STYLE"] != nil {
            navigationController?.pushViewController(CustomStyleViewController(), animated: false)
            return
        }
        guard let debugCategoryId = ProcessInfo.processInfo.environment["NS_DEBUG_CATEGORY"],
              let category = categories.first(where: { $0.id == debugCategoryId }) else { return }
        navigationController?.pushViewController(CategoryStylesViewController(category: category), animated: false)
        #endif
    }

    private func setUpHeader() {
        let logo = UIView()
        logo.backgroundColor = Theme.Color.accentEnd
        logo.layer.cornerRadius = 10
        let logoIcon = UIImageView(image: UIImage(named: "splashIcon"))
        logoIcon.tintColor = .white
        logoIcon.translatesAutoresizingMaskIntoConstraints = false
        logo.addSubview(logoIcon)
        logo.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = "Newborn"
        nameLabel.font = Theme.Font.heading(18, weight: 700)
        nameLabel.textColor = Theme.Color.textPrimaryAlt

        let logoStack = UIStackView(arrangedSubviews: [logo, nameLabel])
        logoStack.axis = .horizontal
        logoStack.spacing = 9
        logoStack.alignment = .center

        let coinIcon = UIImageView(image: UIImage(systemName: "dollarsign.circle.fill"))
        coinIcon.tintColor = Theme.Color.coin
        coinLabel.text = "—"
        coinLabel.font = Theme.Font.body(13, weight: 800)
        coinLabel.textColor = UIColor(hex: 0xB07E1E)
        let coinPill = UIStackView(arrangedSubviews: [coinIcon, coinLabel])
        coinPill.axis = .horizontal
        coinPill.spacing = 5
        coinPill.alignment = .center
        coinPill.isLayoutMarginsRelativeArrangement = true
        coinPill.layoutMargins = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 11)
        coinPill.backgroundColor = Theme.Color.coinBackground
        coinPill.layer.cornerRadius = 14
        coinPill.isUserInteractionEnabled = true
        coinPill.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(coinPillTapped)))

        let header = UIStackView(arrangedSubviews: [logoStack, UIView(), coinPill])
        header.axis = .horizontal
        header.alignment = .center
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        NSLayoutConstraint.activate([
            logo.widthAnchor.constraint(equalToConstant: 30),
            logo.heightAnchor.constraint(equalToConstant: 30),
            logoIcon.centerXAnchor.constraint(equalTo: logo.centerXAnchor),
            logoIcon.centerYAnchor.constraint(equalTo: logo.centerYAnchor),
            logoIcon.heightAnchor.constraint(equalToConstant: 40),
            logoIcon.widthAnchor.constraint(equalToConstant: 40),
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22)
        ])
        headerBottomAnchor = header.bottomAnchor
    }

    private var headerBottomAnchor: NSLayoutYAxisAnchor!

    #if DEBUG
    /// Debug-only aid for testing the push notification pipeline (device token -> APNs -> FCM ->
    /// scheduleTestNotification/sendTestNotification -> back down to the device) end-to-end
    /// without waiting on a real collage to finish generating. Never compiled into a release
    /// build. Pushes headerBottomAnchor down so setUpGrid()'s layout doesn't need to know this
    /// button exists at all.
    private func setUpTestNotificationButton() {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Test Notification (1 min)"
        config.baseBackgroundColor = Theme.Color.purpleAccent
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        button.configuration = config
        button.titleLabel?.font = Theme.Font.heading(13, weight: 700)
        button.addTarget(self, action: #selector(testNotificationTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: headerBottomAnchor, constant: 10),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22)
        ])
        headerBottomAnchor = button.bottomAnchor
    }

    @objc private func testNotificationTapped() {
        HapticFeedback.light()
        Functions.functions().httpsCallable("scheduleTestNotification").call { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    self.presentSimpleAlert(title: "Couldn't Schedule", message: error.localizedDescription)
                } else {
                    self.presentSimpleAlert(title: "Scheduled", message: "A test notification will arrive in about 1 minute — make sure you've allowed notifications and the APNs key is configured in Firebase Console.")
                }
            }
        }
    }

    private func presentSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    #endif

    private func setUpGrid() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 16, left: 22, bottom: 24, right: 22)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CategoryListCell.self, forCellWithReuseIdentifier: CategoryListCell.reuseId)
        collectionView.register(CreateYourOwnStyleCell.self, forCellWithReuseIdentifier: CreateYourOwnStyleCell.reuseId)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerBottomAnchor, constant: 6),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: CreateYourOwnStyleCell.reuseId, for: indexPath)
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryListCell.reuseId, for: indexPath) as! CategoryListCell
        cell.configure(with: categories[indexPath.item - 1])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // "Create Your Own Style" stays a full-width header row; categories below it flow 2-up.
        if indexPath.item == 0 {
            return CGSize(width: collectionView.bounds.width - 44, height: 96)
        }
        let columnWidth = (collectionView.bounds.width - 44 - 14) / 2
        let height = CategoryListCell.height(forName: categories[indexPath.item - 1].name, columnWidth: columnWidth)
        return CGSize(width: columnWidth, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        HapticFeedback.selection()
        if indexPath.item == 0 {
            navigationController?.pushViewController(CustomStyleViewController(), animated: true)
            return
        }
        let styles = CategoryStylesViewController(category: categories[indexPath.item - 1])
        navigationController?.pushViewController(styles, animated: true)
    }

    @objc private func coinPillTapped() {
        HapticFeedback.selection()
        CreditsService.fetchStatus { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                let isPremium = (try? result.get())?.isPremium ?? false
                if isPremium {
                    self.present(CoinPackageViewController.presented(), animated: true)
                } else {
                    self.present(PaywallViewController.presented(), animated: true)
                }
            }
        }
    }
}
