import UIKit

/// Real static copy for both documents (no backend yet — see LegalDocument for the exact text).
final class LegalDocumentViewController: UIViewController {
    private let document: LegalDocument

    init(title: String) {
        self.document = LegalDocument(title: title)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = document.title
        view.backgroundColor = Theme.Color.backgroundCream
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let updatedLabel = UILabel()
        updatedLabel.text = document.lastUpdated
        updatedLabel.font = Theme.Font.body(12, weight: 600)
        updatedLabel.textColor = Theme.Color.textSecondary

        let bodyLabel = UILabel()
        bodyLabel.text = document.body
        bodyLabel.font = Theme.Font.body(14.5, weight: 500)
        bodyLabel.textColor = Theme.Color.textSecondaryAlt
        bodyLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [updatedLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 14
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 24, bottom: 40, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

/// Real copy, not backend-driven yet — kept as a static Swift source of truth (mirrored by
/// Design/Content if that ever needs syncing) until app_settings/legal exists.
private struct LegalDocument {
    let title: String
    let lastUpdated = "Last updated: August 2026"
    let body: String

    init(title: String) {
        self.title = title
        self.body = title == "Privacy Policy" ? Self.privacyBody : Self.termsBody
    }

    private static let privacyBody = """
    Newborn Studio ("we", "us") creates AI-generated studio-style portraits from photos you upload. This policy explains what we collect and why.

    WHAT WE COLLECT
    • Photos you upload to generate a portrait, and the portraits we create for you.
    • Basic usage data (which themes you generate, credit/subscription status) tied to an anonymous device account — we don't require an email, phone number, or name to use the app.
    • Purchase information handled by Apple and our payments provider (RevenueCat) — we never see or store your card details.

    HOW WE USE YOUR PHOTOS
    Uploaded photos are sent to our AI image generation provider (Wiro AI) solely to produce your requested portrait, and are not used to train AI models or shared with any other third party. Generated portraits are stored so you can view them again in your Gallery, tied to your anonymous account.

    CHILDREN'S PHOTOS
    This app is intended to be used by a parent or legal guardian to create portraits of their own child. Do not upload photos of any child without the consent of that child's parent or guardian.

    THIRD-PARTY SERVICES
    We use Firebase (Google) for authentication, storage, and backend functions, Wiro AI for image generation, and RevenueCat for subscription/purchase management. Each processes data only as needed to provide their service to us.

    YOUR CHOICES
    You can delete your account and all associated data at any time from Profile settings. Deleting your account permanently removes your uploaded photos, generated portraits, and purchase history from our systems.

    DATA RETENTION
    We retain your photos and generations only for as long as your account exists. We do not sell your data to third parties or use it for advertising.

    CONTACT
    Questions about this policy can be sent to the support address listed on our App Store page.
    """

    private static let termsBody = """
    By using Newborn Studio, you agree to these terms.

    THE SERVICE
    Newborn Studio lets you upload a photo and generate AI-created studio-style portrait variations using selected themes or your own custom prompt. Results are AI-generated approximations and may not always be usable — we do our best, but generation can occasionally fail or produce unexpected results.

    CREDITS & SUBSCRIPTIONS
    Each generation costs credits. Credits are granted through a subscription (recurring, auto-renewing unless cancelled) or one-time coin purchases. Subscriptions are billed through your Apple ID account and renew automatically unless turned off at least 24 hours before the end of the current period, managed via your device's App Store subscription settings. If a generation fails due to a technical error on our end, the credit spent is automatically refunded to your account.

    ACCEPTABLE USE
    You agree to only upload photos you have the right to use, and only of children whose parent or legal guardian has consented. You agree not to use the app to generate content that is unsafe, exploitative, or otherwise inappropriate involving a minor. We reserve the right to suspend accounts that violate this.

    OWNERSHIP
    You retain rights to the photos you upload. Portraits generated for you are yours to save and share for personal use.

    NO WARRANTY
    The app and its AI-generated output are provided "as is," without warranty of any kind. We're not liable for any indirect or consequential damages arising from your use of the app.

    CHANGES
    We may update these terms as the app evolves; continued use after a change means you accept the updated terms.

    CONTACT
    Questions about these terms can be sent to the support address listed on our App Store page.
    """
}
