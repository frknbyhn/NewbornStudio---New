import UIKit

final class ThemeCardCell: UICollectionViewCell {
    static let reuseId = "ThemeCardCell"

    private static let nameFont = Theme.Font.heading(14, weight: 600)
    /// tintView + top/gap/bottom spacing, everything except the name label's own height.
    private static let fixedHeight: CGFloat = 8 + 100 + 9 + 10
    /// Approximates the label's available width (leading inset + gap + heart button + trailing
    /// inset) — same conservative-is-fine reasoning as CategoryListCell.
    private static let nameLabelWidthInset: CGFloat = 52

    /// Lets sizeForItemAt size each cell to its own name instead of every cell paying for the
    /// longest possible (2-line) name regardless of its own text.
    static func height(forName name: String, columnWidth: CGFloat) -> CGFloat {
        let lines = name.lineCount(font: nameFont, width: columnWidth - nameLabelWidthInset, maxLines: 2)
        return fixedHeight + CGFloat(lines) * ceil(nameFont.lineHeight)
    }

    private let tintView = UIView()
    private let imageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let nameLabel = UILabel()
    private let heartButton = UIButton(type: .system)
    private var imageTask: URLSessionDataTask?

    private var theme: ThemeCard?
    private var isFavorited = false
    var onFavoriteToggle: ((ThemeCard) -> Void)?

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

        spinner.color = Theme.Color.accentEnd
        spinner.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = Self.nameFont
        nameLabel.numberOfLines = 2
        nameLabel.textColor = Theme.Color.textPrimaryAlt
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        heartButton.tintColor = UIColor(hex: 0xD9CBC5)
        heartButton.addTarget(self, action: #selector(heartTapped), for: .touchUpInside)
        heartButton.translatesAutoresizingMaskIntoConstraints = false
        updateHeartIcon()

        contentView.addSubview(tintView)
        tintView.addSubview(imageView)
        tintView.addSubview(spinner)
        contentView.addSubview(nameLabel)
        contentView.addSubview(heartButton)

        NSLayoutConstraint.activate([
            tintView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            tintView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            tintView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            tintView.heightAnchor.constraint(equalToConstant: 100),

            imageView.topAnchor.constraint(equalTo: tintView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: tintView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: tintView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: tintView.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: tintView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: tintView.centerYAnchor),

            nameLabel.topAnchor.constraint(equalTo: tintView.bottomAnchor, constant: 9),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: heartButton.leadingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            // Centered on the first line rather than the whole (possibly two-line) label block,
            // so the heart stays level with the title instead of drifting down when it wraps.
            heartButton.centerYAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor, constant: -6),
            heartButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            heartButton.widthAnchor.constraint(equalToConstant: 32),
            heartButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    func configure(with theme: ThemeCard, isFavorited: Bool = false) {
        self.theme = theme
        self.isFavorited = isFavorited
        updateHeartIcon()

        tintView.backgroundColor = theme.tint
        nameLabel.text = theme.name
        imageView.image = nil
        imageView.alpha = 0
        imageTask?.cancel()

        guard let url = theme.previewImageUrl else { return }
        spinner.startAnimating()
        imageTask = RemoteImageLoader.load(url) { [weak self] image in
            guard let self else { return }
            self.spinner.stopAnimating()
            guard let image else { return }
            self.imageView.image = image
            UIView.animate(withDuration: 0.2) { self.imageView.alpha = 1 }
        }
    }

    private func updateHeartIcon() {
        let symbol = isFavorited ? "heart.fill" : "heart"
        heartButton.setImage(UIImage(systemName: symbol), for: .normal)
        heartButton.tintColor = isFavorited ? Theme.Color.accentEnd : UIColor(hex: 0xD9CBC5)
    }

    @objc private func heartTapped() {
        guard let theme else { return }
        HapticFeedback.light()
        isFavorited.toggle()
        updateHeartIcon()
        onFavoriteToggle?(theme)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        spinner.stopAnimating()
        imageView.image = nil
        imageView.alpha = 0
        onFavoriteToggle = nil
    }
}
