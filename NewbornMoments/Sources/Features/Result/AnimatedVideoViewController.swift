import UIKit
import AVKit
import Photos

/// Shows the animated (image-to-video) result from ResultViewController's "Animate Portrait"
/// action — looping playback, Save (to Photos) and Share. Mirrors MilestoneCollageViewController's
/// dark preview screen (same pattern as every other "here's your generated thing" screen in the
/// app), minus that screen's delete action — nothing to delete here, this video isn't saved to
/// any gallery of its own.
final class AnimatedVideoViewController: UIViewController {
    private let videoURL: URL
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var loopObserver: NSObjectProtocol?

    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItem?.tintColor = .white
        view.backgroundColor = UIColor(hex: 0x2E2530)
        setUpPlayer()
        setUpActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: 0x2E2530)
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        player?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = true
        player?.pause()
    }

    deinit {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
    }

    private var playerContainer: UIView!

    private func setUpPlayer() {
        let container = UIView()
        container.backgroundColor = UIColor(hex: 0x54445A)
        container.layer.cornerRadius = 26
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        playerContainer = container

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120)
        ])

        player = AVPlayer(url: videoURL)
        player.actionAtItemEnd = .none
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        container.layer.addSublayer(playerLayer)

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main
        ) { [weak self] _ in
            self?.player.seek(to: .zero)
            self?.player.play()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = playerContainer?.bounds ?? .zero
    }

    private func setUpActions() {
        let actions = UIStackView(arrangedSubviews: [
            actionButton(icon: "square.and.arrow.down", title: NSLocalizedString("Save", comment: "Video screen action button"), action: #selector(saveTapped)),
            actionButton(icon: "square.and.arrow.up", title: NSLocalizedString("Share", comment: "Video screen action button"), action: #selector(shareTapped))
        ])
        actions.axis = .horizontal
        actions.distribution = .equalSpacing
        actions.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actions)

        NSLayoutConstraint.activate([
            actions.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actions.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func actionButton(icon: String, title: String, action: Selector) -> UIView {
        let circle = UIButton(type: .system)
        circle.setImage(UIImage(systemName: icon), for: .normal)
        circle.tintColor = .white
        circle.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        circle.layer.cornerRadius = 25
        circle.addTarget(self, action: action, for: .touchUpInside)
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.widthAnchor.constraint(equalToConstant: 50).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let label = UILabel()
        label.text = title
        label.font = Theme.Font.body(11, weight: 600)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [circle, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 5
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
        return stack
    }

    @objc private func closeTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func saveTapped() {
        HapticFeedback.light()
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                guard let self else { return }
                guard status == .authorized || status == .limited else {
                    self.presentAlert(title: NSLocalizedString("Photos Access Needed", comment: "Photo library access error title"), message: NSLocalizedString("Allow photo library access in Settings to save the video.", comment: "Photo library access error message"))
                    return
                }
                self.withLocalFileURL { localURL in
                    guard let localURL else {
                        self.presentAlert(title: NSLocalizedString("Couldn't Save", comment: "Save error title"), message: NSLocalizedString("Something went wrong saving the video. Please try again.", comment: "Save error message"))
                        return
                    }
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localURL)
                    }) { success, _ in
                        DispatchQueue.main.async {
                            if success {
                                HapticFeedback.success()
                                self.presentAlert(title: NSLocalizedString("Saved!", comment: "Save success title"), message: NSLocalizedString("The animated video was saved to your Photos.", comment: "Save success message"))
                            } else {
                                self.presentAlert(title: NSLocalizedString("Couldn't Save", comment: "Save error title"), message: NSLocalizedString("Something went wrong saving the video. Please try again.", comment: "Save error message"))
                            }
                        }
                    }
                }
            }
        }
    }

    @objc private func shareTapped() {
        HapticFeedback.light()
        withLocalFileURL { [weak self] localURL in
            guard let self, let localURL else { return }
            self.present(UIActivityViewController(activityItems: [localURL], applicationActivities: nil), animated: true)
        }
    }

    /// The video is always a remote Firebase Storage URL here (animateResult's response) —
    /// AVPlayer streams that fine for playback, but PHAssetChangeRequest/UIActivityViewController
    /// both need an actual local file, so this downloads it to a temp file first (brief spinner).
    private func withLocalFileURL(completion: @escaping (URL?) -> Void) {
        if videoURL.isFileURL {
            completion(videoURL)
            return
        }
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        let task = URLSession.shared.downloadTask(with: videoURL) { tempURL, _, _ in
            var destination: URL?
            if let tempURL {
                let dest = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                try? FileManager.default.removeItem(at: dest)
                if (try? FileManager.default.moveItem(at: tempURL, to: dest)) != nil {
                    destination = dest
                }
            }
            DispatchQueue.main.async {
                spinner.removeFromSuperview()
                completion(destination)
            }
        }
        task.resume()
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .default))
        present(alert, animated: true)
    }
}
