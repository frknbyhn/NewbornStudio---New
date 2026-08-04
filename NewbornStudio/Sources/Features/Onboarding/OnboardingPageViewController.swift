import UIKit

final class OnboardingPageViewController: UIViewController {
    let pageIndex: Int
    let page: OnboardingPage
    private let totalPages: Int
    var onSkip: (() -> Void)?

    private let backgroundLayer = CAGradientLayer()

    init(page: OnboardingPage, pageIndex: Int, totalPages: Int) {
        self.page = page
        self.pageIndex = pageIndex
        self.totalPages = totalPages
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBackground()
        setUpContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundLayer.frame = view.bounds
    }

    private func setUpBackground() {
        backgroundLayer.colors = page.backgroundGradient.map(\.cgColor)
        backgroundLayer.locations = [0, 0.52, 1]
        backgroundLayer.startPoint = CGPoint(x: 0.5, y: 0)
        backgroundLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(backgroundLayer, at: 0)
    }

    private func setUpContent() {
        // Skip button
        if page.showsSkip {
            let skip = UIButton(type: .system)
            skip.setTitle("Skip", for: .normal)
            skip.setTitleColor(page.skipColor, for: .normal)
            skip.titleLabel?.font = Theme.Font.heading(14, weight: 600)
            skip.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
            skip.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(skip)
            NSLayoutConstraint.activate([
                skip.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
                skip.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26)
            ])
        }

        // Illustration circle
        let circle = UIView()
        circle.backgroundColor = UIColor(hex: 0xFFF7F0)
        circle.layer.cornerRadius = 125
        circle.layer.shadowColor = page.shadowColor.cgColor
        circle.layer.shadowOpacity = 0.5
        circle.layer.shadowRadius = 20
        circle.layer.shadowOffset = CGSize(width: 0, height: 20)
        circle.translatesAutoresizingMaskIntoConstraints = false

        let illustration = UIImageView(image: UIImage(named: page.illustrationName))
        illustration.contentMode = .scaleAspectFill
        illustration.clipsToBounds = true
        illustration.layer.cornerRadius = 98
        illustration.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(illustration)

        let title = UILabel()
        title.text = page.title
        title.font = Theme.Font.heading(27, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.textAlignment = .center
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel()
        subtitle.text = page.subtitle
        subtitle.font = Theme.Font.body(14.5, weight: 500)
        subtitle.textColor = Theme.Color.textSecondary
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let contentStack = UIStackView(arrangedSubviews: [circle, title, subtitle])
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 18
        contentStack.setCustomSpacing(24, after: circle)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: 250),
            circle.heightAnchor.constraint(equalToConstant: 250),
            illustration.widthAnchor.constraint(equalToConstant: 196),
            illustration.heightAnchor.constraint(equalToConstant: 196),
            illustration.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            illustration.centerYAnchor.constraint(equalTo: circle.centerYAnchor),

            // Bottom inset (dots + CTA height + spacing) reserved so this content stays clear
            // of the container's persistent, non-sliding controls overlaid on top.
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 34),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -34),
            contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            title.widthAnchor.constraint(lessThanOrEqualToConstant: 330),
            subtitle.widthAnchor.constraint(lessThanOrEqualToConstant: 290)
        ])
    }

    @objc private func skipTapped() {
        HapticFeedback.selection()
        onSkip?()
    }
}
