import UIKit
import StoreKit

/// One-time "rate us" screen between onboarding and the paywall. Auto-scrolls to the bottom
/// (locking interaction while it does) so the reviews get read before Continue is reachable.
final class RatingViewController: UIViewController {
    var onFinished: (() -> Void)?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let continueButton = GradientPillButton(title: NSLocalizedString("Continue", comment: "Rating screen continue button"), height: 54)
    private var hasAutoScrolled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpScrollView()
        setUpContent()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        scrollView.contentInset.bottom = view.safeAreaInsets.bottom
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAutoScrolled else { return }
        hasAutoScrolled = true
        autoScrollToBottom()
    }

    private func setUpScrollView() {
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 72),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -24)
        ])
    }

    private func setUpContent() {
        let heroStars = Self.starsRow(pointSize: 36, spacing: 6)
        let heroWrapper = UIStackView(arrangedSubviews: [UIView(), heroStars, UIView()])
        heroWrapper.distribution = .equalCentering
        stack.addArrangedSubview(heroWrapper)

        let title = UILabel()
        title.text = NSLocalizedString("rating.title", comment: "Rating screen title")
        title.font = Theme.Font.heading(30, weight: 700)
        title.textColor = Theme.Color.textPrimary
        title.textAlignment = .center
        title.numberOfLines = 0
        stack.addArrangedSubview(title)

        let body = UILabel()
        body.text = NSLocalizedString("rating.body", comment: "Rating screen body")
        body.font = Theme.Font.body(15)
        body.textColor = Theme.Color.textSecondary
        body.textAlignment = .center
        body.numberOfLines = 0
        stack.addArrangedSubview(body)

        for review in RatingReviewStore.all {
            stack.addArrangedSubview(Self.reviewCard(review))
        }

        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        stack.addArrangedSubview(continueButton)
    }

    private static func starsRow(pointSize: CGFloat, spacing: CGFloat) -> UIView {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize)
        let stars = (0..<5).map { _ -> UIImageView in
            let star = UIImageView(image: UIImage(systemName: "star.fill", withConfiguration: config))
            star.tintColor = Theme.Color.accentEnd
            star.contentMode = .scaleAspectFit
            star.setContentHuggingPriority(.required, for: .horizontal)
            star.setContentCompressionResistancePriority(.required, for: .horizontal)
            return star
        }
        let row = UIStackView(arrangedSubviews: stars)
        row.axis = .horizontal
        row.spacing = spacing
        return row
    }

    private static func reviewCard(_ review: RatingReview) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = Theme.Shape.cardRadius
        card.layer.borderWidth = 1 / UIScreen.main.scale
        card.layer.borderColor = Theme.Color.backgroundTaupe.cgColor

        let stars = starsRow(pointSize: 14, spacing: 2)
        let starsWrapper = UIStackView(arrangedSubviews: [stars, UIView()])

        let title = UILabel()
        title.text = review.title
        title.font = Theme.Font.heading(16, weight: 600)
        title.textColor = Theme.Color.textPrimary
        title.numberOfLines = 0

        let body = UILabel()
        body.text = review.body
        body.font = Theme.Font.body(14)
        body.textColor = Theme.Color.textSecondary
        body.numberOfLines = 0

        let author = UILabel()
        author.text = review.nickname
        author.font = Theme.Font.body(12, weight: 500)
        author.textColor = Theme.Color.accentEnd

        let content = UIStackView(arrangedSubviews: [starsWrapper, title, body, author])
        content.axis = .vertical
        content.spacing = 6
        content.setCustomSpacing(10, after: body)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18)
        ])
        return card
    }

    /// Scrolls to the bottom once, with the scroll view locked for the whole ride (and the short
    /// lead-in wait) so nobody can scroll or hit Continue before the reviews have gone by.
    private func autoScrollToBottom() {
        view.layoutIfNeeded()
        let maxOffset = scrollView.contentSize.height + view.safeAreaInsets.bottom - scrollView.bounds.height
        guard maxOffset > 0 else { return }

        scrollView.isUserInteractionEnabled = false
        let duration = min(max(maxOffset / 180, 2.5), 8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
                self.scrollView.contentOffset = CGPoint(x: 0, y: maxOffset)
            } completion: { _ in
                self.scrollView.isUserInteractionEnabled = true
            }
        }
    }

    @objc private func continueTapped() {
        HapticFeedback.selection()
        continueButton.isEnabled = false
        if let scene = view.window?.windowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        // requestReview has no completion callback, so give the system prompt a moment before moving on.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.onFinished?()
        }
    }
}
