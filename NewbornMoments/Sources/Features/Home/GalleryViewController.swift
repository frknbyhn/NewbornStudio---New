import UIKit

final class GalleryViewController: UIViewController {
    private enum Tab: Int { case history, favorites }

    private var collectionView: UICollectionView!
    private var segmentedControl: UISegmentedControl!
    private var generations: [Generation] = []
    private var favoriteThemes: [ThemeCard] = []
    private var favoriteIds: Set<String> = []
    private let emptyStateView = UIView()
    private let emptyTitle = UILabel()
    private let emptySubtitle = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private var selectedTab: Tab = .history

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpSegmentedControl()
        setUpGrid()
        setUpEmptyState()
        setUpSpinner()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyDebugTabIfNeeded()
        loadCurrentTab()
    }

    private func applyDebugTabIfNeeded() {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["NS_DEBUG_GALLERY_SEGMENT"] == "favorites" else { return }
        segmentedControl.selectedSegmentIndex = Tab.favorites.rawValue
        selectedTab = .favorites
        updateEmptyStateCopy()
        #endif
    }

    private func setUpSegmentedControl() {
        segmentedControl = UISegmentedControl(items: [
            NSLocalizedString("History", comment: "Gallery segment"),
            NSLocalizedString("Favorites", comment: "Gallery segment")
        ])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.selectedSegmentTintColor = Theme.Color.accentEnd
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: Theme.Font.heading(13, weight: 700)], for: .selected)
        segmentedControl.setTitleTextAttributes([.foregroundColor: Theme.Color.textSecondaryAlt, .font: Theme.Font.heading(13, weight: 600)], for: .normal)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 36)
        ])
        segmentBottomAnchor = segmentedControl.bottomAnchor
    }

    private var segmentBottomAnchor: NSLayoutYAxisAnchor!

    @objc private func segmentChanged() {
        HapticFeedback.selection()
        selectedTab = Tab(rawValue: segmentedControl.selectedSegmentIndex) ?? .history
        updateEmptyStateCopy()
        collectionView.reloadData()
        loadCurrentTab()
    }

    private func loadCurrentTab() {
        switch selectedTab {
        case .history: loadGenerations()
        case .favorites: loadFavorites()
        }
    }

    private func setUpSpinner() {
        spinner.color = Theme.Color.accentEnd
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadGenerations() {
        spinner.startAnimating()
        GenerationService.fetchGenerations { [weak self] result in
            DispatchQueue.main.async {
                guard let self, self.selectedTab == .history else { return }
                self.spinner.stopAnimating()
                switch result {
                case .success(let generations):
                    self.generations = generations
                    self.collectionView.reloadData()
                    self.emptyStateView.isHidden = !generations.isEmpty
                    self.collectionView.isHidden = generations.isEmpty
                case .failure(let error):
                    print("GenerationService.fetchGenerations failed: \(error)")
                    self.emptyStateView.isHidden = !self.generations.isEmpty
                }
            }
        }
    }

    private func loadFavorites() {
        spinner.startAnimating()
        FavoritesService.fetchFavoriteThemes { [weak self] result in
            DispatchQueue.main.async {
                guard let self, self.selectedTab == .favorites else { return }
                self.spinner.stopAnimating()
                switch result {
                case .success(let themes):
                    self.favoriteThemes = themes
                    self.favoriteIds = Set(themes.map(\.id))
                    self.collectionView.reloadData()
                    self.emptyStateView.isHidden = !themes.isEmpty
                    self.collectionView.isHidden = themes.isEmpty
                case .failure(let error):
                    print("FavoritesService.fetchFavoriteThemes failed: \(error)")
                    self.emptyStateView.isHidden = !self.favoriteThemes.isEmpty
                }
            }
        }
    }

    private func setUpGrid() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 20, bottom: 24, right: 20)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.reuseId)
        collectionView.register(ThemeCardCell.self, forCellWithReuseIdentifier: ThemeCardCell.reuseId)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isHidden = true
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: segmentBottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setUpEmptyState() {
        let icon = UIImageView(image: UIImage(systemName: "photo.stack"))
        icon.tintColor = UIColor(hex: 0xD9CBC5)
        icon.contentMode = .scaleAspectFit

        emptyTitle.font = Theme.Font.heading(18, weight: 700)
        emptyTitle.textColor = Theme.Color.textPrimaryAlt
        emptyTitle.textAlignment = .center

        emptySubtitle.font = Theme.Font.body(14, weight: 500)
        emptySubtitle.textColor = Theme.Color.textSecondary
        emptySubtitle.textAlignment = .center
        emptySubtitle.numberOfLines = 0

        updateEmptyStateCopy()

        let stack = UIStackView(arrangedSubviews: [icon, emptyTitle, emptySubtitle])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(20, after: icon)
        stack.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(stack)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 56),
            icon.heightAnchor.constraint(equalToConstant: 56),
            stack.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: emptyStateView.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: emptyStateView.trailingAnchor, constant: -40),
            emptyStateView.topAnchor.constraint(equalTo: segmentBottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateEmptyStateCopy() {
        switch selectedTab {
        case .history:
            emptyTitle.text = NSLocalizedString("No portraits yet", comment: "Gallery history empty state title")
            emptySubtitle.text = NSLocalizedString("Generate your first studio portrait and it will show up here.", comment: "Gallery history empty state subtitle")
        case .favorites:
            emptyTitle.text = NSLocalizedString("No favorites yet", comment: "Gallery favorites empty state title")
            emptySubtitle.text = NSLocalizedString("Tap the heart on any style to save it here.", comment: "Gallery favorites empty state subtitle")
        }
    }
}

extension GalleryViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedTab == .history ? generations.count : favoriteThemes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch selectedTab {
        case .history:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GalleryCell.reuseId, for: indexPath) as! GalleryCell
            cell.configure(with: generations[indexPath.item])
            return cell
        case .favorites:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThemeCardCell.reuseId, for: indexPath) as! ThemeCardCell
            let theme = favoriteThemes[indexPath.item]
            cell.configure(with: theme, isFavorited: true)
            cell.onFavoriteToggle = { [weak self] theme in
                guard let self else { return }
                FavoritesService.toggle(styleId: theme.id)
                self.favoriteThemes.removeAll { $0.id == theme.id }
                self.collectionView.reloadData()
                self.emptyStateView.isHidden = !self.favoriteThemes.isEmpty
                self.collectionView.isHidden = self.favoriteThemes.isEmpty
            }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 20 * 2 - 12) / 2
        switch selectedTab {
        case .history: return CGSize(width: width, height: width * 1.3)
        case .favorites:
            let height = ThemeCardCell.height(forName: favoriteThemes[indexPath.item].name, columnWidth: width)
            return CGSize(width: width, height: height)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        HapticFeedback.selection()
        switch selectedTab {
        case .history:
            let generation = generations[indexPath.item]
            let theme = ThemeCard(id: generation.styleId, name: generation.styleName, tint: Theme.Color.purpleBackground, previewImageUrl: nil)
            let result = ResultViewController(theme: theme, sourceImage: nil, resultUrl: generation.resultUrl)
            navigationController?.pushViewController(result, animated: true)
        case .favorites:
            let upload = PhotoUploadViewController(theme: favoriteThemes[indexPath.item])
            navigationController?.pushViewController(upload, animated: true)
        }
    }
}

final class GalleryCell: UICollectionViewCell {
    static let reuseId = "GalleryCell"
    private let imageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var imageTask: URLSessionDataTask?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = Theme.Color.backgroundWarm
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = Theme.Color.accentEnd
        spinner.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        contentView.addSubview(spinner)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with generation: Generation) {
        imageView.image = nil
        spinner.startAnimating()
        imageTask = RemoteImageLoader.load(generation.resultUrl) { [weak self] image in
            self?.spinner.stopAnimating()
            self?.imageView.image = image
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        spinner.stopAnimating()
        imageView.image = nil
    }
}
