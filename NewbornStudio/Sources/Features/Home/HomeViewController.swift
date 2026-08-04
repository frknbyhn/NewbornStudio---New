import UIKit

final class HomeViewController: UIViewController {
    private let coinLabel = UILabel()
    private var collectionView: UICollectionView!
    private var filtersStack: UIStackView!
    private var filterChips: [FilterChipButton] = []
    private var categories: [ThemeCategory] = []
    private var selectedCategoryId: String?
    private var themes: [ThemeCard] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpHeader()
        setUpFilters()
        setUpGrid()
        loadCategories()
        loadThemes()
    }

    private func loadCategories() {
        ThemeService.fetchCategories { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let categories):
                self.categories = categories
                self.populateFilterChips()
            case .failure(let error):
                print("ThemeService.fetchCategories failed: \(error)")
            }
        }
    }

    private func loadThemes() {
        ThemeService.fetchThemes(categoryId: selectedCategoryId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let cards):
                self.themes = cards
                self.collectionView.reloadData()
            case .failure(let error):
                // Firestore is briefly unreachable right after a cold start — the grid just
                // stays empty rather than showing a raw error, matching the offline-state rule.
                print("ThemeService.fetchThemes failed: \(error)")
            }
        }
    }

    private func setUpHeader() {
        let logo = UIView()
        logo.backgroundColor = Theme.Color.accentEnd
        logo.layer.cornerRadius = 10
        let logoIcon = UIImageView(image: UIImage(systemName: "figure.child"))
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
        coinLabel.text = "48"
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
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22)
        ])
        headerBottomAnchor = header.bottomAnchor
    }

    private var headerBottomAnchor: NSLayoutYAxisAnchor!
    private var filtersBottomAnchor: NSLayoutYAxisAnchor!

    private func setUpFilters() {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        filtersStack = UIStackView()
        filtersStack.axis = .horizontal
        filtersStack.spacing = 8
        filtersStack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(filtersStack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: headerBottomAnchor, constant: 14),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.heightAnchor.constraint(equalToConstant: 31),
            filtersStack.topAnchor.constraint(equalTo: scroll.topAnchor),
            filtersStack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            filtersStack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 22),
            filtersStack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -22)
        ])
        filtersBottomAnchor = scroll.bottomAnchor
    }

    private func populateFilterChips() {
        filterChips.forEach { $0.removeFromSuperview() }
        filterChips = []

        let allChip = FilterChipButton(title: "All", categoryId: nil)
        allChip.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        filtersStack.addArrangedSubview(allChip)
        filterChips.append(allChip)

        for category in categories {
            let chip = FilterChipButton(title: category.name, categoryId: category.id)
            chip.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
            filtersStack.addArrangedSubview(chip)
            filterChips.append(chip)
        }
        updateChipSelection()
    }

    private func updateChipSelection() {
        for chip in filterChips {
            chip.isSelectedChip = chip.categoryId == selectedCategoryId
        }
    }

    @objc private func filterTapped(_ sender: FilterChipButton) {
        guard sender.categoryId != selectedCategoryId else { return }
        HapticFeedback.selection()
        selectedCategoryId = sender.categoryId
        updateChipSelection()
        loadThemes()
    }

    private func setUpGrid() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 14
        layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 14, left: 22, bottom: 24, right: 22)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ThemeCardCell.self, forCellWithReuseIdentifier: ThemeCardCell.reuseId)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: filtersBottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        themes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThemeCardCell.reuseId, for: indexPath) as! ThemeCardCell
        cell.configure(with: themes[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 22 * 2 - 14) / 2
        return CGSize(width: width, height: width * 0.92)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        HapticFeedback.selection()
        let upload = PhotoUploadViewController(theme: themes[indexPath.item])
        navigationController?.pushViewController(upload, animated: true)
    }

    @objc private func coinPillTapped() {
        HapticFeedback.selection()
        navigationController?.pushViewController(CoinPackageViewController(), animated: true)
    }
}

/// A UILabel with real horizontal padding baked into its intrinsic content size — used for pill-shaped filter chips.
final class PaddedLabel: UILabel {
    var horizontalPadding: CGFloat = 12

    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(width: base.width + horizontalPadding * 2, height: base.height)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: horizontalPadding, dy: 0))
    }
}

/// A tappable pill chip for Home's category filter row.
final class FilterChipButton: UIControl {
    let categoryId: String?
    private let label = PaddedLabel()

    var isSelectedChip: Bool = false {
        didSet { updateAppearance() }
    }

    init(title: String, categoryId: String?) {
        self.categoryId = categoryId
        super.init(frame: .zero)
        label.text = title
        label.font = Theme.Font.heading(13, weight: 600)
        label.textAlignment = .center
        label.horizontalPadding = 15
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        layer.cornerRadius = 15.5
        layer.masksToBounds = true
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        heightAnchor.constraint(equalToConstant: 31).isActive = true
        setContentHuggingPriority(.required, for: .horizontal)
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func updateAppearance() {
        if isSelectedChip {
            backgroundColor = Theme.Color.accentEnd
            label.textColor = .white
        } else {
            backgroundColor = Theme.Color.backgroundWarm
            label.textColor = Theme.Color.textSecondaryAlt
        }
    }
}
