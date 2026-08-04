import UIKit

final class CategoryStylesViewController: UIViewController {
    private let category: ThemeCategory
    private var collectionView: UICollectionView!
    private var themes: [ThemeCard] = []
    private var favoriteIds: Set<String> = []

    init(category: ThemeCategory) {
        self.category = category
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpNavBar()
        setUpGrid()
        loadThemes()
        loadFavorites()
    }

    private func loadFavorites() {
        FavoritesService.fetchFavoriteIds { [weak self] result in
            guard let self, case .success(let ids) = result else { return }
            self.favoriteIds = ids
            self.collectionView.reloadData()
        }
    }

    private func setUpNavBar() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        back.tintColor = Theme.Color.textSecondaryAlt
        back.backgroundColor = Theme.Color.backgroundWarm
        back.layer.cornerRadius = 12
        back.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        back.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = category.name
        title.font = Theme.Font.heading(19, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.numberOfLines = 1

        let bar = UIStackView(arrangedSubviews: [back, title])
        bar.axis = .horizontal
        bar.spacing = 14
        bar.alignment = .center
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)

        NSLayoutConstraint.activate([
            back.widthAnchor.constraint(equalToConstant: 38),
            back.heightAnchor.constraint(equalToConstant: 38),
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            bar.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -22)
        ])
        navBarBottom = bar.bottomAnchor
    }

    private var navBarBottom: NSLayoutYAxisAnchor!

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
            collectionView.topAnchor.constraint(equalTo: navBarBottom, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadThemes() {
        ThemeService.fetchThemes(categoryId: category.id, limit: 30) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let cards):
                self.themes = cards
                self.collectionView.reloadData()
                self.debugAutoFavoriteIfNeeded()
                self.debugAutoOpenFirstStyleIfNeeded()
            case .failure(let error):
                print("ThemeService.fetchThemes failed: \(error)")
            }
        }
    }

    private func debugAutoOpenFirstStyleIfNeeded() {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["NS_DEBUG_AUTO_OPEN_FIRST_STYLE"] != nil,
              let first = themes.first else { return }
        navigationController?.pushViewController(PhotoUploadViewController(theme: first), animated: false)
        #endif
    }

    private func debugAutoFavoriteIfNeeded() {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["NS_DEBUG_AUTO_FAVORITE_FIRST"] != nil,
              let first = themes.first else { return }
        favoriteIds.insert(first.id)
        FavoritesService.toggle(styleId: first.id)
        collectionView.reloadData()
        #endif
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension CategoryStylesViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        themes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThemeCardCell.reuseId, for: indexPath) as! ThemeCardCell
        let theme = themes[indexPath.item]
        cell.configure(with: theme, isFavorited: favoriteIds.contains(theme.id))
        cell.onFavoriteToggle = { [weak self] theme in
            guard let self else { return }
            if self.favoriteIds.contains(theme.id) {
                self.favoriteIds.remove(theme.id)
            } else {
                self.favoriteIds.insert(theme.id)
            }
            FavoritesService.toggle(styleId: theme.id)
        }
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
}
