import UIKit

/// Temporary placeholder root — replaced by the onboarding/tab-bar flow in Phase 5.
final class RootViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream

        let label = UILabel()
        label.text = "Newborn Studio"
        label.font = Theme.Font.heading(28, weight: 700)
        label.textColor = Theme.Color.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
