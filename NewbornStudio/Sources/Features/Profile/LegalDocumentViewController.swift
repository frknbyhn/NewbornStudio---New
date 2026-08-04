import UIKit

/// Placeholder shell — real copy is read from Firestore `app_settings/legal` once
/// the admin panel exists (Phase 6.5), so it can be edited without a build.
final class LegalDocumentViewController: UIViewController {
    private let documentTitle: String

    init(title: String) {
        self.documentTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = documentTitle
        view.backgroundColor = Theme.Color.backgroundCream
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))

        let label = UILabel()
        label.text = "\(documentTitle) text goes here — pulled from Firestore app_settings/legal once the backend exists."
        label.font = Theme.Font.body(15, weight: 500)
        label.textColor = Theme.Color.textSecondaryAlt
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
