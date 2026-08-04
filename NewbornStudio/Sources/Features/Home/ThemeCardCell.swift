import UIKit

final class ThemeCardCell: UICollectionViewCell {
    static let reuseId = "ThemeCardCell"

    private let tintView = UIView()
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
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

        tintView.layer.cornerRadius = 16
        tintView.layer.masksToBounds = true
        tintView.translatesAutoresizingMaskIntoConstraints = false

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.alpha = 0
        imageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = Theme.Font.heading(14, weight: 600)
        nameLabel.textColor = Theme.Color.textPrimaryAlt
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let heart = UIImageView(image: UIImage(systemName: "heart"))
        heart.tintColor = UIColor(hex: 0xD9CBC5)
        heart.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(tintView)
        tintView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(heart)

        NSLayoutConstraint.activate([
            tintView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            tintView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            tintView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            tintView.heightAnchor.constraint(equalToConstant: 100),

            imageView.topAnchor.constraint(equalTo: tintView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: tintView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: tintView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: tintView.bottomAnchor),

            nameLabel.topAnchor.constraint(equalTo: tintView.bottomAnchor, constant: 9),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            heart.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            heart.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            heart.widthAnchor.constraint(equalToConstant: 18),
            heart.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    func configure(with theme: ThemeCard) {
        tintView.backgroundColor = theme.tint
        nameLabel.text = theme.name
        imageView.image = nil
        imageView.alpha = 0
        imageTask?.cancel()

        guard let url = theme.previewImageUrl else { return }
        imageTask = RemoteImageLoader.load(url) { [weak self] image in
            guard let self, let image else { return }
            self.imageView.image = image
            UIView.animate(withDuration: 0.2) { self.imageView.alpha = 1 }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageView.image = nil
        imageView.alpha = 0
    }
}
