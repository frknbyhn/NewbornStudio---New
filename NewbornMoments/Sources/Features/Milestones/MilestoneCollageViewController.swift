import UIKit
import AVKit
import Photos

/// Shows the rendered collage video with looping playback, Save (to Photos) and Share — mirrors
/// ResultViewController's dark preview screen so the two "here's your generated thing" moments
/// in the app feel like the same pattern.
final class MilestoneCollageViewController: UIViewController {
    private let videoURL: URL
    private let listName: String
    /// Id of the Firestore/Storage doc this collage is (or will shortly be, if the upload from
    /// a just-finished render is still in flight — see MilestoneCollageStore.saveCollage) saved
    /// under. Always present — both call sites (a fresh render, or opening one from "My Collages")
    /// have it up front — so the delete action always has something to target.
    private let collageId: String
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var loopObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?
    private let loadingSpinner = UIActivityIndicatorView(style: .large)
    private var containerAspectConstraint: NSLayoutConstraint?
    private let musicPromptTextView = UITextView()
    private let musicPromptPlaceholder = UILabel()
    private let generateMusicButton = GradientPillButton(title: "Generate Music", icon: UIImage(systemName: "music.note"))
    private let musicCreditLabel = UILabel()
    private let musicSpinner = UIActivityIndicatorView(style: .medium)
    /// Must match functions/generateCollageMusic.js's own MUSIC_CREDIT_COST constant — nothing
    /// enforces that at compile time, it's just the two places this number happens to live (same
    /// pattern as MilestoneListDetailViewController.creditCostPerItem).
    private static let musicCreditCost = 1

    init(videoURL: URL, listName: String, collageId: String) {
        self.videoURL = videoURL
        self.listName = listName
        self.collageId = collageId
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(deleteTapped))
        navigationItem.leftBarButtonItem?.tintColor = .white
        view.backgroundColor = UIColor(hex: 0x2E2530)
        // Built bottom-up so the video container (below) can cap its height against the top of
        // this stack instead of a magic constant — see setUpPlayer's aspectConstraint comment.
        setUpActions()
        setUpMusicPromptSection()
        setUpPlayer()
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
        statusObservation?.invalidate()
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

        // Placeholder 9:16 aspect (this screen only ever shows videos from MilestoneVideoRenderer's
        // fixed vertical canvas or an "Animate Portrait" clip, both tall) while the real one loads —
        // swapped for the actual ratio once the player item is ready, same idea as
        // ResultViewController's applyRealAspectRatio for its image. defaultHigh (not required) so
        // the bottomAnchor cap below always wins if a real ratio would ever push the container
        // past the space actually available above the action buttons.
        let aspectConstraint = container.heightAnchor.constraint(equalTo: container.widthAnchor, multiplier: 16.0 / 9.0)
        aspectConstraint.priority = .defaultHigh
        containerAspectConstraint = aspectConstraint

        loadingSpinner.color = .white
        loadingSpinner.startAnimating()
        loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(loadingSpinner)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            container.bottomAnchor.constraint(lessThanOrEqualTo: musicSectionTop, constant: -16),
            aspectConstraint,
            loadingSpinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            loadingSpinner.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        player = AVPlayer(url: videoURL)
        player.actionAtItemEnd = .none
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.isHidden = true // stays hidden (spinner only) until the item is actually ready
        container.layer.addSublayer(playerLayer)

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main
        ) { [weak self] _ in
            self?.player.seek(to: .zero)
            self?.player.play()
        }

        statusObservation = player.currentItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self, item.status != .unknown else { return }
                self.loadingSpinner.stopAnimating()
                self.playerLayer.isHidden = false
                if item.status == .readyToPlay {
                    self.applyRealAspectRatio()
                }
            }
        }
    }

    /// Reads the actual video dimensions (accounting for any rotation via preferredTransform, the
    /// standard gotcha with AVAsset's naturalSize) once the item is ready, and resizes the
    /// container to match instead of the 9:16 placeholder guess.
    private func applyRealAspectRatio() {
        guard let track = player.currentItem?.asset.tracks(withMediaType: .video).first else { return }
        let size = track.naturalSize.applying(track.preferredTransform)
        let width = abs(size.width)
        let height = abs(size.height)
        guard width > 0, height > 0 else { return }
        containerAspectConstraint?.isActive = false
        let newConstraint = playerContainer.heightAnchor.constraint(equalTo: playerContainer.widthAnchor, multiplier: height / width)
        newConstraint.priority = .defaultHigh
        newConstraint.isActive = true
        containerAspectConstraint = newConstraint
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = playerContainer?.bounds ?? .zero
    }

    private func setUpActions() {
        let actions = UIStackView(arrangedSubviews: [
            actionButton(icon: "square.and.arrow.down", title: "Save", action: #selector(saveTapped)),
            actionButton(icon: "square.and.arrow.up", title: "Share", action: #selector(shareTapped))
        ])
        actions.axis = .horizontal
        actions.distribution = .equalSpacing
        actions.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actions)

        NSLayoutConstraint.activate([
            actions.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actions.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
        actionsTop = actions.topAnchor
    }

    private var actionsTop: NSLayoutYAxisAnchor!

    /// Offers to generate a music track for the collage video — mirrors ResultViewController's
    /// themed edit-prompt card (same card styling, placeholder-as-UILabel trick since UITextView
    /// has no native placeholder), plus a full-width button underneath instead of an inline send
    /// arrow, since "Generate Music" reads better as its own CTA than a chat-style send icon.
    /// generateMusicTapped() only starts the job (startCollageMusic) and returns to My Collages —
    /// see its own doc comment for why this doesn't wait around on this screen.
    private func setUpMusicPromptSection() {
        let question = UILabel()
        question.text = "Want music for this collage?"
        question.font = Theme.Font.heading(15, weight: 700)
        question.textColor = .white
        question.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(question)

        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        musicPromptTextView.backgroundColor = .clear
        musicPromptTextView.textColor = .white
        musicPromptTextView.tintColor = Theme.Color.accentEnd
        musicPromptTextView.font = Theme.Font.body(14, weight: 600)
        musicPromptTextView.isScrollEnabled = false
        musicPromptTextView.textContainerInset = .zero
        musicPromptTextView.textContainer.lineFragmentPadding = 0
        musicPromptTextView.delegate = self
        musicPromptTextView.translatesAutoresizingMaskIntoConstraints = false

        musicPromptPlaceholder.text = "Describe the music — e.g. \u{201c}soft, dreamy piano lullaby, gentle and warm\u{201d}"
        musicPromptPlaceholder.font = Theme.Font.body(14, weight: 600)
        musicPromptPlaceholder.textColor = UIColor.white.withAlphaComponent(0.4)
        musicPromptPlaceholder.numberOfLines = 2
        musicPromptPlaceholder.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(musicPromptTextView)
        card.addSubview(musicPromptPlaceholder)
        view.addSubview(card)

        generateMusicButton.addTarget(self, action: #selector(generateMusicTapped), for: .touchUpInside)
        generateMusicButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(generateMusicButton)

        musicSpinner.color = .white
        musicSpinner.hidesWhenStopped = true
        musicSpinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(musicSpinner)

        // Must match functions/generateCollageMusic.js's own MUSIC_CREDIT_COST — see
        // Self.musicCreditCost's own comment.
        musicCreditLabel.text = "\(Self.musicCreditCost) Credit"
        musicCreditLabel.font = Theme.Font.body(12.5, weight: 700)
        musicCreditLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        musicCreditLabel.textAlignment = .center
        musicCreditLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(musicCreditLabel)

        NSLayoutConstraint.activate([
            question.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            question.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),

            card.topAnchor.constraint(equalTo: question.bottomAnchor, constant: 10),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            card.heightAnchor.constraint(equalToConstant: 68),

            musicPromptTextView.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            musicPromptTextView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            musicPromptTextView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            musicPromptTextView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),

            musicPromptPlaceholder.topAnchor.constraint(equalTo: musicPromptTextView.topAnchor),
            musicPromptPlaceholder.leadingAnchor.constraint(equalTo: musicPromptTextView.leadingAnchor),
            musicPromptPlaceholder.trailingAnchor.constraint(equalTo: musicPromptTextView.trailingAnchor),

            generateMusicButton.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 12),
            generateMusicButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            generateMusicButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            generateMusicButton.heightAnchor.constraint(equalToConstant: 52),

            musicSpinner.centerXAnchor.constraint(equalTo: generateMusicButton.centerXAnchor),
            musicSpinner.centerYAnchor.constraint(equalTo: generateMusicButton.centerYAnchor),

            musicCreditLabel.topAnchor.constraint(equalTo: generateMusicButton.bottomAnchor, constant: 6),
            musicCreditLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            musicCreditLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            musicCreditLabel.bottomAnchor.constraint(equalTo: actionsTop, constant: -20)
        ])
        musicSectionTop = question.topAnchor
    }

    private var musicSectionTop: NSLayoutYAxisAnchor!

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

    @objc private func deleteTapped() {
        HapticFeedback.light()
        let alert = UIAlertController(
            title: "Delete This Collage?",
            message: "The \u{201c}\(listName)\u{201d} collage video will be permanently deleted. This can't be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDelete()
        })
        present(alert, animated: true)
    }

    private func performDelete() {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false

        MilestoneCollageStore.deleteCollage(id: collageId) { [weak self] success in
            guard let self else { return }
            if success {
                HapticFeedback.success()
                self.navigationController?.popViewController(animated: true)
            } else {
                spinner.removeFromSuperview()
                self.navigationItem.leftBarButtonItem?.isEnabled = true
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.presentAlert(title: "Couldn't Delete", message: "Something went wrong deleting the collage. Please try again.")
            }
        }
    }

    @objc private func saveTapped() {
        HapticFeedback.light()
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                guard let self else { return }
                guard status == .authorized || status == .limited else {
                    self.presentAlert(title: "Photos Access Needed", message: "Allow photo library access in Settings to save the video.")
                    return
                }
                self.withLocalFileURL { localURL in
                    guard let localURL else {
                        self.presentAlert(title: "Couldn't Save", message: "Something went wrong saving the video. Please try again.")
                        return
                    }
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localURL)
                    }) { success, _ in
                        DispatchQueue.main.async {
                            if success {
                                HapticFeedback.success()
                                self.presentAlert(title: "Saved!", message: "The collage video was saved to your Photos.")
                            } else {
                                self.presentAlert(title: "Couldn't Save", message: "Something went wrong saving the video. Please try again.")
                            }
                        }
                    }
                }
            }
        }
    }

    @objc private func generateMusicTapped() {
        let prompt = musicPromptTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            HapticFeedback.light()
            presentAlert(title: "Describe the Music", message: "Enter a short description of what you'd like the track to sound like.")
            return
        }
        HapticFeedback.light()
        CreditsService.requireCredits(atLeast: Self.musicCreditCost, presentingFrom: self) { [weak self] in
            self?.startMusicGeneration(prompt: prompt)
        }
    }

    /// startCollageMusic itself only validates/charges/enqueues (finishes in seconds — the
    /// spinner here covers just that round trip), but the actual work behind it (a Wiro
    /// text-to-music call, then an ffmpeg mux pass onto this video) runs in the background across
    /// renderCollageMusic, the same reasoning as the collage video itself: easily long enough
    /// that staying on this screen waiting isn't reasonable. So a successful call here doesn't
    /// keep the user on this screen either — it hands off to My Collages, where the row shows
    /// its usual "preparing" treatment until the music is actually mixed in.
    private func startMusicGeneration(prompt: String) {
        setMusicGenerating(true)
        CollageAnimationService.startMusic(collageId: collageId, prompt: prompt) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.setMusicGenerating(false)
                switch result {
                case .success:
                    HapticFeedback.success()
                    self.presentMusicStartedAlert()
                case .failure(let error):
                    self.presentAlert(title: "Couldn't Start Music", message: error.localizedDescription)
                }
            }
        }
    }

    private func presentMusicStartedAlert() {
        let alert = UIAlertController(
            title: "Adding Your Music",
            message: "We're mixing your track into this collage. You can follow its progress from the My Collages screen.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Go to My Collages", style: .default) { [weak self] _ in
            self?.goToMyCollages()
        })
        present(alert, animated: true)
    }

    /// Pops back to an already-on-the-stack My Collages screen (this player is often reached BY
    /// tapping a row there) instead of pushing a duplicate on top of it; only pushes a fresh one
    /// when this screen was reached some other way (e.g. straight off a fresh collage render).
    private func goToMyCollages() {
        guard let nav = navigationController else { return }
        if let gallery = nav.viewControllers.last(where: { $0 is MilestoneCollageGalleryViewController }) {
            nav.popToViewController(gallery, animated: true)
        } else {
            nav.pushViewController(MilestoneCollageGalleryViewController(), animated: true)
        }
    }

    private func setMusicGenerating(_ generating: Bool) {
        generateMusicButton.isUserInteractionEnabled = !generating
        generateMusicButton.alpha = generating ? 0.5 : 1
        musicPromptTextView.isEditable = !generating
        if generating {
            musicSpinner.startAnimating()
        } else {
            musicSpinner.stopAnimating()
        }
    }

    @objc private func shareTapped() {
        HapticFeedback.light()
        withLocalFileURL { [weak self] localURL in
            guard let self, let localURL else { return }
            self.present(UIActivityViewController(activityItems: [localURL], applicationActivities: nil), animated: true)
        }
    }

    /// The video is a local file URL when this screen was just pushed straight off a fresh
    /// render (see MilestoneListDetailViewController) — used as-is. Opened from the "My Collages"
    /// gallery instead, it's a remote Storage URL: AVPlayer streams that fine for playback, but
    /// PHAssetChangeRequest/UIActivityViewController both need an actual local file, so this
    /// downloads it to a temp file first (with a brief spinner) whenever it isn't one already.
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
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension MilestoneCollageViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        musicPromptPlaceholder.isHidden = !textView.text.isEmpty
    }
}
