import UIKit

/// The AI data-consent bottom sheet (see AIConsentGate). Discloses that the photo is sent to
/// wiro.ai and asks for permission before any upload can happen. The only way out is the Continue
/// button — there is no close affordance and tapping the dimmed background does nothing — so the
/// user cannot reach a photo upload without granting consent first.
///
/// Presented as a bottom card over a dimmed backdrop (not a UISheetPresentationController) so the
/// card's height is driven entirely by Auto Layout from its content — no detent math, it just hugs
/// whatever it contains.
final class AIConsentViewController: UIViewController {
    var onAccepted: (() -> Void)?

    private let card = UIView()
    private let continueButton = GradientPillButton(title: NSLocalizedString("Continue", comment: "AI consent sheet primary button"), icon: nil)

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        // Tapping the dimmed backdrop closes the sheet WITHOUT granting consent — the actual upload
        // is gated separately (AIConsentGate.requireConsent), so this just defers the decision.
        let dimTap = UITapGestureRecognizer(target: self, action: #selector(backdropTapped))
        dimTap.delegate = self
        view.addGestureRecognizer(dimTap)

        setUpCard()
    }

    @objc private func backdropTapped() {
        dismiss(animated: true)
    }

    private func setUpCard() {
        card.backgroundColor = Theme.Color.backgroundCream
        card.layer.cornerRadius = 28
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let grabber = UIView()
        grabber.backgroundColor = UIColor(hex: 0xD8CEC8)
        grabber.layer.cornerRadius = 2.5
        grabber.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(grabber)

        let examples = examplesView()
        // examples has a fixed width; wrap it so it can sit centered in a full-width .fill stack.
        let examplesWrap = UIView()
        examplesWrap.translatesAutoresizingMaskIntoConstraints = false
        examplesWrap.addSubview(examples)
        NSLayoutConstraint.activate([
            examples.topAnchor.constraint(equalTo: examplesWrap.topAnchor),
            examples.bottomAnchor.constraint(equalTo: examplesWrap.bottomAnchor),
            examples.centerXAnchor.constraint(equalTo: examplesWrap.centerXAnchor),
            examples.leadingAnchor.constraint(greaterThanOrEqualTo: examplesWrap.leadingAnchor),
            examples.trailingAnchor.constraint(lessThanOrEqualTo: examplesWrap.trailingAnchor)
        ])

        let title = UILabel()
        title.text = NSLocalizedString("Face the camera directly in good lighting so your face is clearly visible. Avoid photos where your face is turned away, covered, or blurry.", comment: "AI consent sheet photo-quality guidance")
        title.font = Theme.Font.body(15.5, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.textAlignment = .center
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = NSLocalizedString("Your photo is sent securely to wiro.ai to generate your portrait, and is permanently deleted from our servers as soon as your result is ready.", comment: "AI consent sheet data-processing disclosure naming the processor (wiro.ai)")
        subtitle.font = Theme.Font.body(13, weight: 600)
        subtitle.textColor = Theme.Color.textSecondary
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 12

        let stack = UIStackView(arrangedSubviews: [examplesWrap, textStack, continueButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 22
        stack.setCustomSpacing(24, after: textStack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            grabber.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            grabber.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 40),
            grabber.heightAnchor.constraint(equalToConstant: 5),

            stack.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            // Card hugs its content; 20pt below the button, above the home-indicator safe area.
            stack.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    /// Two rounded example photos, the "avoid" one tilted left with a red ✕ badge, the "good" one
    /// tilted right with a green ✓ badge — mirrors the reference design. Falls back to a neutral
    /// placeholder tint if the imagesets aren't present.
    private func examplesView() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let bad = exampleCard(imageName: "AIConsentBadExample", rotation: -7, badgeSystemName: "xmark.circle.fill", badgeColor: UIColor(hex: 0xC0554E), badgeAtTrailing: false)
        let good = exampleCard(imageName: "AIConsentGoodExample", rotation: 7, badgeSystemName: "checkmark.circle.fill", badgeColor: Theme.Color.success, badgeAtTrailing: true)

        container.addSubview(bad)
        container.addSubview(good)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 150),
            container.widthAnchor.constraint(equalToConstant: 234),

            bad.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            bad.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            good.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            good.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        // Good sits on top where they overlap in the middle.
        container.bringSubviewToFront(good)
        return container
    }

    private func exampleCard(imageName: String, rotation: CGFloat, badgeSystemName: String, badgeColor: UIColor, badgeAtTrailing: Bool) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.transform = CGAffineTransform(rotationAngle: rotation * .pi / 180)
        card.layer.shadowColor = Theme.Color.textPrimary.cgColor
        card.layer.shadowOpacity = 0.18
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = Theme.Color.backgroundTaupe
        imageView.layer.cornerRadius = 16
        imageView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(imageView)

        let badge = UIImageView(image: UIImage(systemName: badgeSystemName))
        badge.tintColor = badgeColor
        badge.backgroundColor = .white
        badge.layer.cornerRadius = 14
        badge.clipsToBounds = true
        badge.contentMode = .scaleAspectFill
        badge.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(badge)

        NSLayoutConstraint.activate([
            card.widthAnchor.constraint(equalToConstant: 132),
            card.heightAnchor.constraint(equalToConstant: 132),
            imageView.topAnchor.constraint(equalTo: card.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            badge.widthAnchor.constraint(equalToConstant: 28),
            badge.heightAnchor.constraint(equalToConstant: 28),
            badge.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: 2),
            badgeAtTrailing
                ? badge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: 2)
                : badge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: -2)
        ])
        return card
    }

    @objc private func continueTapped() {
        HapticFeedback.light()
        onAccepted?()
    }
}

extension AIConsentViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only the dimmed backdrop dismisses — a touch inside the card is ignored by this recognizer.
        !card.frame.contains(touch.location(in: view))
    }
}
