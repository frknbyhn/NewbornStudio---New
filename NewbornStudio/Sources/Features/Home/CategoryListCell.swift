import UIKit

final class CategoryListCell: UICollectionViewCell {
    static let reuseId = "CategoryListCell"

    private let coverView = UIView()
    private let imageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let nameLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    private var imageTask: URLSessionDataTask?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUp() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 22
        contentView.layer.shadowColor = Theme.Color.textPrimary.cgColor
        contentView.layer.shadowOpacity = 0.08
        contentView.layer.shadowRadius = 10
        contentView.layer.shadowOffset = CGSize(width: 0, height: 6)

        coverView.backgroundColor = Theme.Color.backgroundWarm
        coverView.layer.cornerRadius = 16
        coverView.layer.masksToBounds = true
        coverView.translatesAutoresizingMaskIntoConstraints = false

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.alpha = 0
        imageView.translatesAutoresizingMaskIntoConstraints = false

        spinner.color = Theme.Color.accentEnd
        spinner.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = Theme.Font.heading(16, weight: 700)
        nameLabel.textColor = Theme.Color.textPrimaryAlt
        nameLabel.numberOfLines = 2

        chevron.tintColor = UIColor(hex: 0xCBBDB8)
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        coverView.addSubview(imageView)
        coverView.addSubview(spinner)
        let textStack = UIStackView(arrangedSubviews: [nameLabel, UIView(), chevron])
        textStack.axis = .horizontal
        textStack.alignment = .center

        let stack = UIStackView(arrangedSubviews: [coverView, textStack])
        stack.axis = .vertical
        stack.spacing = 10
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 10, right: 10)
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            coverView.heightAnchor.constraint(equalToConstant: 130),
            imageView.topAnchor.constraint(equalTo: coverView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: coverView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: coverView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: coverView.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: coverView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: coverView.centerYAnchor)
        ])
    }

    func configure(with category: ThemeCategory) {
        nameLabel.text = category.name
        imageView.image = nil
        imageView.alpha = 0
        imageTask?.cancel()

        guard let url = category.coverImageUrl else {
            spinner.stopAnimating()
            return
        }
        spinner.startAnimating()
        imageTask = RemoteImageLoader.load(url) { [weak self] image in
            guard let self else { return }
            self.spinner.stopAnimating()
            guard let image else { return }
            self.imageView.image = image
            UIView.animate(withDuration: 0.2) { self.imageView.alpha = 1 }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        spinner.stopAnimating()
        imageView.image = nil
        imageView.alpha = 0
    }
}
