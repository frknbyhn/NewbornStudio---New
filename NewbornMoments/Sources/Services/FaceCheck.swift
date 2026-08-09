import UIKit

/// Shared UI wrapper around FaceDetectionService — shows a brief blocking spinner while Vision
/// runs, then either proceeds or shows an error alert. Used by every photo-picking screen.
enum FaceCheck {
    static func run(on image: UIImage, presentingFrom viewController: UIViewController, onPassed: @escaping () -> Void) {
        let overlay = UIActivityIndicatorView(style: .large)
        overlay.color = Theme.Color.accentEnd
        overlay.startAnimating()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        let dim = UIView()
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        dim.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(dim)
        viewController.view.addSubview(overlay)
        NSLayoutConstraint.activate([
            dim.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            dim.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            dim.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            overlay.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            overlay.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])

        // [weak viewController] — Vision runs in well under a second in practice, but there's
        // no hard bound on it, and a strong capture here would keep a screen the user already
        // left alive (liable to try presenting an alert on top of whatever replaced it) until
        // it resolves.
        FaceDetectionService.detectFaceCount(in: image) { [weak viewController] outcome in
            dim.removeFromSuperview()
            overlay.removeFromSuperview()
            guard let viewController else { return }
            switch outcome {
            case .ok:
                onPassed()
            case .noFace:
                presentError(
                    from: viewController,
                    title: NSLocalizedString("No Face Detected", comment: "Face detection error alert title"),
                    message: NSLocalizedString("We couldn't find a face in this photo. Please choose a clear, well-lit photo of your baby's face.", comment: "Face detection error alert message")
                )
            case .multipleFaces:
                presentError(
                    from: viewController,
                    title: NSLocalizedString("Multiple Faces Detected", comment: "Face detection error alert title"),
                    message: NSLocalizedString("This photo has more than one face. Please choose a photo with just your baby in it.", comment: "Face detection error alert message")
                )
            }
        }
    }

    private static func presentError(from viewController: UIViewController, title: String, message: String) {
        HapticFeedback.error()
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .default))
        viewController.present(alert, animated: true)
    }
}
