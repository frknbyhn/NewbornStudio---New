import UIKit

/// Empty until the Firestore-backed generation history exists (Phase 6).
final class GalleryViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream

        let icon = UIImageView(image: UIImage(systemName: "photo.stack"))
        icon.tintColor = UIColor(hex: 0xD9CBC5)
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = "No portraits yet"
        title.font = Theme.Font.heading(18, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Generate your first studio portrait and it will show up here."
        subtitle.font = Theme.Font.body(14, weight: 500)
        subtitle.textColor = Theme.Color.textSecondary
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [icon, title, subtitle])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(20, after: icon)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 56),
            icon.heightAnchor.constraint(equalToConstant: 56),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
    }
}
