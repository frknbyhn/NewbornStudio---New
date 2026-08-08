import UIKit

/// Pinned as the first row in Home's category list — routes to CustomStyleViewController
/// instead of a category drill-down.
final class CreateYourOwnStyleCell: UICollectionViewCell {
    static let reuseId = "CreateYourOwnStyleCell"
    private let gradientLayer = CAGradientLayer.accentPill()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUp() {
        // Shadow lives on the cell's own layer (not clipped); the gradient + corner radius live
        // on contentView (clipped) — putting both on one layer would make cornerRadius clipping
        // and an outward shadow mutually exclusive.
        layer.shadowColor = Theme.Color.accentEnd.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)

        contentView.layer.cornerRadius = 22
        contentView.layer.masksToBounds = true
        contentView.layer.insertSublayer(gradientLayer, at: 0)

        let badge = UIView()
        badge.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        badge.layer.cornerRadius = 16
        badge.translatesAutoresizingMaskIntoConstraints = false

        let wand = UIImageView(image: UIImage(systemName: "wand.and.stars"))
        wand.tintColor = .white
        wand.contentMode = .scaleAspectFit
        wand.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(wand)

        let title = UILabel()
        title.text = "Create Your Own Style"
        title.font = Theme.Font.heading(17, weight: 700)
        title.textColor = .white

        let subtitle = UILabel()
        subtitle.text = "Describe any idea — we'll bring it to life"
        subtitle.adjustsFontSizeToFitWidth = true
        subtitle.font = Theme.Font.body(12.5, weight: 600)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.85)
        subtitle.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 2

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor.white.withAlphaComponent(0.85)
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [badge, textStack, UIView(), chevron])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)

        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 46),
            badge.heightAnchor.constraint(equalToConstant: 46),
            wand.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            wand.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            wand.widthAnchor.constraint(equalToConstant: 24),
            wand.heightAnchor.constraint(equalToConstant: 24),

            row.topAnchor.constraint(equalTo: contentView.topAnchor),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
    }
}
