import UIKit

final class GalleryViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var generations: [Generation] = []
    private let emptyStateView = UIView()
    private let spinner = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpGrid()
        setUpEmptyState()
        setUpSpinner()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadGenerations()
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
                guard let self else { return }
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
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isHidden = true
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setUpEmptyState() {
        let icon = UIImageView(image: UIImage(systemName: "photo.stack"))
        icon.tintColor = UIColor(hex: 0xD9CBC5)
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = "No portraits yet"
        title.font = Theme.Font.heading(18, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Generate your first studio portrait and it will show up here."
        subtitle.font = Theme.Font.body(14, weight: 500)
        subtitle.textColor = Theme.Color.textSecondary
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [icon, title, subtitle])
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
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension GalleryViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        generations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GalleryCell.reuseId, for: indexPath) as! GalleryCell
        cell.configure(with: generations[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 20 * 2 - 12) / 2
        return CGSize(width: width, height: width * 1.3)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        HapticFeedback.selection()
        let detail = GalleryDetailViewController(generation: generations[indexPath.item])
        present(detail, animated: true)
    }
}

final class GalleryCell: UICollectionViewCell {
    static let reuseId = "GalleryCell"
    private let imageView = UIImageView()
    private var imageTask: URLSessionDataTask?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = Theme.Color.backgroundWarm
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with generation: Generation) {
        imageView.image = nil
        imageTask = RemoteImageLoader.load(generation.resultUrl) { [weak self] image in
            self?.imageView.image = image
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageView.image = nil
    }
}
