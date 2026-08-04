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

        FaceDetectionService.detectFaceCount(in: image) { outcome in
            dim.removeFromSuperview()
            overlay.removeFromSuperview()
            switch outcome {
            case .ok:
                onPassed()
            case .noFace:
                presentError(
                    from: viewController,
                    title: "No Face Detected",
                    message: "We couldn't find a face in this photo. Please choose a clear, well-lit photo of your baby's face."
                )
            case .multipleFaces:
                presentError(
                    from: viewController,
                    title: "Multiple Faces Detected",
                    message: "This photo has more than one face. Please choose a photo with just your baby in it."
                )
            }
        }
    }

    private static func presentError(from viewController: UIViewController, title: String, message: String) {
        HapticFeedback.error()
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}
