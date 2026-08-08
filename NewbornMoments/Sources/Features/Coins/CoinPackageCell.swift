import UIKit

final class CoinPackageRow: UIControl {
    let package: CoinPackage
    private let radio = UIView()
    private let radioDot = UIView()

    var isSelectedPackage: Bool = false {
        didSet { updateSelection() }
    }

    init(package: CoinPackage) {
        self.package = package
        super.init(frame: .zero)
        setUp()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUp() {
        layer.cornerRadius = Theme.Shape.cardRadius
        layer.borderWidth = 2
        isUserInteractionEnabled = true

        radio.layer.cornerRadius = 11
        radio.layer.borderWidth = 2
        radio.translatesAutoresizingMaskIntoConstraints = false
        radioDot.backgroundColor = Theme.Color.accentEnd
        radioDot.layer.cornerRadius = 6
        radioDot.translatesAutoresizingMaskIntoConstraints = false
        radio.addSubview(radioDot)

        let coinBg = UIView()
        coinBg.backgroundColor = .white
        coinBg.layer.cornerRadius = 16
        let coinIcon = UIImageView(image: UIImage(systemName: "dollarsign.circle.fill"))
        coinIcon.tintColor = Theme.Color.coin
        coinIcon.translatesAutoresizingMaskIntoConstraints = false
        coinBg.addSubview(coinIcon)
        coinBg.translatesAutoresizingMaskIntoConstraints = false

        let coinsLabel = UILabel()
        coinsLabel.text = String(format: NSLocalizedString("%d coins", comment: "Coin package amount, %d is a number"), package.credits)
        coinsLabel.font = Theme.Font.heading(18, weight: 700)
        coinsLabel.textColor = Theme.Color.textPrimaryAlt

        let nameLabel = UILabel()
        nameLabel.text = package.name
        nameLabel.font = Theme.Font.body(11.5, weight: 600)
        nameLabel.textColor = Theme.Color.textSecondary

        let textStack = UIStackView(arrangedSubviews: [coinsLabel, nameLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let priceLabel = UILabel()
        priceLabel.text = package.priceLabel
        priceLabel.font = Theme.Font.heading(18, weight: 700)
        priceLabel.textColor = Theme.Color.textPrimaryAlt

        let row = UIStackView(arrangedSubviews: [radio, coinBg, textStack, UIView(), priceLabel])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            radio.widthAnchor.constraint(equalToConstant: 22),
            radio.heightAnchor.constraint(equalToConstant: 22),
            radioDot.widthAnchor.constraint(equalToConstant: 12),
            radioDot.heightAnchor.constraint(equalToConstant: 12),
            radioDot.centerXAnchor.constraint(equalTo: radio.centerXAnchor),
            radioDot.centerYAnchor.constraint(equalTo: radio.centerYAnchor),
            coinBg.widthAnchor.constraint(equalToConstant: 52),
            coinBg.heightAnchor.constraint(equalToConstant: 52),
            coinIcon.centerXAnchor.constraint(equalTo: coinBg.centerXAnchor),
            coinIcon.centerYAnchor.constraint(equalTo: coinBg.centerYAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        if package.isPopular {
            let badge = PaddedLabel()
            badge.text = NSLocalizedString("MOST POPULAR", comment: "Coin package badge")
            badge.horizontalPadding = 12
            badge.font = Theme.Font.heading(10, weight: 700)
            badge.textColor = .white
            badge.backgroundColor = Theme.Color.accentEnd
            badge.layer.cornerRadius = 9
            badge.layer.masksToBounds = true
            badge.translatesAutoresizingMaskIntoConstraints = false
            addSubview(badge)
            NSLayoutConstraint.activate([
                badge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                badge.topAnchor.constraint(equalTo: topAnchor, constant: -10),
                badge.heightAnchor.constraint(equalToConstant: 18)
            ])
        }

        updateSelection()
    }

    private func updateSelection() {
        radio.layer.borderColor = (isSelectedPackage ? Theme.Color.accentEnd : UIColor(hex: 0xE4D8CF)).cgColor
        radioDot.isHidden = !isSelectedPackage
        layer.borderColor = (isSelectedPackage ? Theme.Color.accentEnd : UIColor(hex: 0xF0E6DF)).cgColor
        backgroundColor = isSelectedPackage ? UIColor(hex: 0xFFF4F1) : .white
    }
}
