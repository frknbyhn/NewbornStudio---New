import UIKit

final class HomeViewController: UIViewController {
    private let coinLabel = UILabel()
    private var collectionView: UICollectionView!
    private let filters = ["New", "Trending", "Milestones", "Fantasy", "Seasonal"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpHeader()
        setUpFilters()
        setUpGrid()
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

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        for (index, filter) in filters.enumerated() {
            let chip = PaddedLabel()
            chip.text = filter
            chip.font = Theme.Font.heading(13, weight: 600)
            chip.textAlignment = .center
            chip.isUserInteractionEnabled = false
            if index == 0 {
                chip.backgroundColor = Theme.Color.accentEnd
                chip.textColor = .white
            } else {
                chip.backgroundColor = Theme.Color.backgroundWarm
                chip.textColor = Theme.Color.textSecondaryAlt
            }
            chip.horizontalPadding = 15
            chip.layer.cornerRadius = 15.5
            chip.layer.masksToBounds = true
            chip.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(chip)
            chip.heightAnchor.constraint(equalToConstant: 31).isActive = true
            chip.setContentHuggingPriority(.required, for: .horizontal)
        }

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: headerBottomAnchor, constant: 14),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.heightAnchor.constraint(equalToConstant: 31),
            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -22)
        ])
        filtersBottomAnchor = scroll.bottomAnchor
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
        ThemeCard.samples.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThemeCardCell.reuseId, for: indexPath) as! ThemeCardCell
        cell.configure(with: ThemeCard.samples[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 22 * 2 - 14) / 2
        return CGSize(width: width, height: width * 0.92)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        HapticFeedback.selection()
        let upload = PhotoUploadViewController(theme: ThemeCard.samples[indexPath.item])
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
