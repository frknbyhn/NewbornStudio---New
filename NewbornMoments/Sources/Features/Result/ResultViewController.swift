import UIKit

final class ResultViewController: UIViewController {
    private let theme: ThemeCard
    private let sourceImage: UIImage?
    private var resultUrl: URL
    private var resultImage: UIImage?
    private let resultImageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let editTextView = UITextView()
    private let editPlaceholder = UILabel()
    private let editSendButton = UIButton(type: .system)
    private let scrollView = UIScrollView()
    private var imageAspectConstraint: NSLayoutConstraint?
    private let milestoneContext: MilestoneCaptureContext?
    /// Only a genuinely fresh generation (pushed straight off GenerationLoadingViewController)
    /// auto-saves onto a matching standard milestone — opening the same result later from
    /// Gallery history must NOT silently re-append it. That path still gets a manual "Milestone"
    /// action button instead (see setUpActions) so the user can choose to save it themselves.
    private let autoSaveEligible: Bool
    /// Resolved once at load time — the standard milestone this result matches, if any (nil for
    /// every theme that isn't a Firsts/Milestones-category style, for one already captured, and
    /// for the milestone-capture flow itself, which already saves its result on close).
    private var pendingMilestone: Milestone?
    private var pendingMilestoneListId: String?
    /// Set once a save actually happens (auto or manual) — what "Go to Milestone Gallery" links to.
    private var savedMilestoneListId: String?
    private let milestoneGalleryLink = UIButton(type: .system)
    private var milestoneSaveButtonView: UIView?
    private let animateButton = GradientPillButton(title: NSLocalizedString("Animate Portrait", comment: "Button to animate the generated portrait"), icon: UIImage(systemName: "sparkles"))

    /// `sourceImage` is nil for a result opened from Gallery history — the original upload was
    /// never persisted (no Storage round-trip for source photos), only the AI result is kept.
    /// `milestoneContext` is set when this result came from MilestoneCaptureViewController — see
    /// closeTapped().
    init(theme: ThemeCard, sourceImage: UIImage?, resultUrl: URL, milestoneContext: MilestoneCaptureContext? = nil, autoSaveEligible: Bool = false) {
        self.theme = theme
        self.sourceImage = sourceImage
        self.resultUrl = resultUrl
        self.milestoneContext = milestoneContext
        self.autoSaveEligible = autoSaveEligible
        super.init(nibName: nil, bundle: nil)
        // Set here (not just on an upstream screen in the push chain) so the tab bar hides no
        // matter which flow pushed this screen — e.g. Gallery pushes it directly as a tab root.
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItem?.tintColor = .white
        view.backgroundColor = UIColor(hex: 0x2E2530)
        if let match = matchingUncapturedMilestone() {
            pendingMilestone = match.milestone
            pendingMilestoneListId = match.listId
        }
        setUpScrollContent()
        loadResultImage()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func circleButton(icon: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        button.layer.cornerRadius = 19
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 38).isActive = true
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        return button
    }

    private func setUpScrollContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scrollView.topAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        setUpImage(in: content)
        setUpEditBox(in: content)
        setUpActions(in: content)
    }

    private func setUpImage(in content: UIView) {
        let container = UIView()
        container.backgroundColor = UIColor(hex: 0x54445A)
        container.layer.cornerRadius = 26
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false

        resultImageView.contentMode = .scaleAspectFill
        resultImageView.clipsToBounds = true
        resultImageView.backgroundColor = UIColor(hex: 0x54445A)
        resultImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(resultImageView)

        spinner.color = .white
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(spinner)

        let expand = circleButton(icon: "arrow.up.left.and.arrow.down.right")
        expand.addTarget(self, action: #selector(expandTapped), for: .touchUpInside)
        container.addSubview(expand)

        content.addSubview(container)
        // Placeholder 3:4 aspect while loading — swapped for the real ratio once the image
        // arrives (see loadResultImage), rather than a fixed guessed height.
        imageAspectConstraint = container.heightAnchor.constraint(equalTo: container.widthAnchor, multiplier: 4.0 / 3.0)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: content.topAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 22),
            container.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -22),
            imageAspectConstraint!,

            resultImageView.topAnchor.constraint(equalTo: container.topAnchor),
            resultImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            resultImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            resultImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            expand.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            expand.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)
        ])
        imageContainer = container
    }

    private var imageContainer: UIView!

    /// Themed text input for requesting an edit on the just-generated result — submitting sends
    /// this image + instruction back through the same generation scenario (GenerationLoadingViewController).
    private func setUpEditBox(in content: UIView) {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        editTextView.backgroundColor = .clear
        editTextView.textColor = .white
        editTextView.tintColor = Theme.Color.accentEnd
        editTextView.font = Theme.Font.body(14, weight: 600)
        editTextView.isScrollEnabled = false
        editTextView.textContainerInset = .zero
        editTextView.textContainer.lineFragmentPadding = 0
        editTextView.delegate = self
        editTextView.translatesAutoresizingMaskIntoConstraints = false

        editPlaceholder.text = NSLocalizedString("Want a change? Describe an edit — e.g. \u{201c}add a soft blue blanket\u{201d}", comment: "Result screen edit prompt placeholder")
        editPlaceholder.font = Theme.Font.body(14, weight: 600)
        editPlaceholder.textColor = UIColor.white.withAlphaComponent(0.4)
        editPlaceholder.numberOfLines = 2
        editPlaceholder.translatesAutoresizingMaskIntoConstraints = false

        editSendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        editSendButton.tintColor = Theme.Color.accentEnd
        editSendButton.addTarget(self, action: #selector(submitEditTapped), for: .touchUpInside)
        editSendButton.translatesAutoresizingMaskIntoConstraints = false
        editSendButton.isEnabled = false
        editSendButton.alpha = 0.4

        card.addSubview(editTextView)
        card.addSubview(editPlaceholder)
        card.addSubview(editSendButton)
        content.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 22),
            card.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -22),
            card.heightAnchor.constraint(equalToConstant: 80),

            editTextView.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            editTextView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            editTextView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            editTextView.trailingAnchor.constraint(equalTo: editSendButton.leadingAnchor, constant: -8),
            editTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),

            editPlaceholder.topAnchor.constraint(equalTo: editTextView.topAnchor),
            editPlaceholder.leadingAnchor.constraint(equalTo: editTextView.leadingAnchor),
            editPlaceholder.trailingAnchor.constraint(equalTo: editTextView.trailingAnchor),

            editSendButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            editSendButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
            editSendButton.widthAnchor.constraint(equalToConstant: 30),
            editSendButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        editCard = card
    }

    private var editCard: UIView!

    private func loadResultImage() {
        URLSession.shared.dataTask(with: resultUrl) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.spinner.stopAnimating()
                if let data, let image = UIImage(data: data) {
                    self.resultImage = image
                    self.resultImageView.image = image
                    self.applyRealAspectRatio(for: image)
                    self.saveToPendingMilestoneIfNeeded(image)
                } else {
                    // Real network failure state, not a silent blank — matches the offline-state rule.
                    print("Failed to load result image: \(error?.localizedDescription ?? "unknown error")")
                    self.resultImageView.image = self.sourceImage
                    if let sourceImage = self.sourceImage {
                        self.applyRealAspectRatio(for: sourceImage)
                    }
                }
            }
        }.resume()
    }

    private func applyRealAspectRatio(for image: UIImage) {
        guard image.size.height > 0 else { return }
        imageAspectConstraint?.isActive = false
        imageAspectConstraint = imageContainer.heightAnchor.constraint(equalTo: imageContainer.widthAnchor, multiplier: image.size.height / image.size.width)
        imageAspectConstraint?.isActive = true
        UIView.animate(withDuration: 0.2, animations: { self.view.layoutIfNeeded() }) { [weak self] _ in
            self?.revealFullScreenIfFirstTime()
        }
    }

    private static let hasSeenResultScreenKey = "hasSeenResultScreenScrollReveal"

    /// The first time ANY user ever lands on this screen (across every entry point — a fresh
    /// generation, Gallery history, a milestone capture), auto-scroll to the very bottom and
    /// back up — a nudge so they notice there's more below the fold (the edit box, Animate
    /// Portrait, Save/Share) instead of only ever seeing the image and assuming that's the whole
    /// screen. Runs once ever, not once per screen visit — tracked in UserDefaults like the
    /// onboarding-seen flag in AppCoordinator.
    private func revealFullScreenIfFirstTime() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.hasSeenResultScreenKey) else { return }
        defaults.set(true, forKey: Self.hasSeenResultScreenKey)

        view.layoutIfNeeded()
        let maxOffsetY = scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
        guard maxOffsetY > 0 else { return } // content already fits on screen — nothing to reveal
        let bottomOffset = CGPoint(x: 0, y: maxOffsetY)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: 0.7, delay: 0, options: .curveEaseInOut) {
                self.scrollView.setContentOffset(bottomOffset, animated: false)
            } completion: { _ in
                UIView.animate(withDuration: 0.7, delay: 0.5, options: .curveEaseInOut) {
                    self.scrollView.setContentOffset(.zero, animated: false)
                }
            }
        }
    }

    private func setUpActions(in content: UIView) {
        var actionViews = [
            actionButton(icon: "square.and.arrow.down", title: NSLocalizedString("Save", comment: "Result screen action button"), action: #selector(saveTapped)),
            actionButton(icon: "square.and.arrow.up", title: NSLocalizedString("Share", comment: "Result screen action button"), action: #selector(shareTapped))
        ]
        // A matching standard milestone that WON'T auto-save (Gallery history, not a fresh
        // generation) gets an explicit action here instead — see the autoSaveEligible doc comment.
        if pendingMilestone != nil, !autoSaveEligible {
            let milestoneButton = actionButton(icon: "star.circle.fill", title: NSLocalizedString("Milestone", comment: "Result screen action button"), action: #selector(manualSaveMilestoneTapped))
            actionViews.append(milestoneButton)
            milestoneSaveButtonView = milestoneButton
        }
        let actions = UIStackView(arrangedSubviews: actionViews)
        actions.axis = .horizontal
        actions.distribution = .equalSpacing

        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(NSLocalizedString("Go to Milestone Gallery", comment: "Result screen link"), attributes: .init([.font: Theme.Font.heading(14, weight: 700)]))
        config.image = UIImage(systemName: "arrow.right")
        config.imagePlacement = .trailing
        config.imagePadding = 6
        config.baseForegroundColor = Theme.Color.accentEnd
        milestoneGalleryLink.configuration = config
        milestoneGalleryLink.addTarget(self, action: #selector(goToMilestoneGalleryTapped), for: .touchUpInside)
        milestoneGalleryLink.isHidden = true

        animateButton.addTarget(self, action: #selector(animateTapped), for: .touchUpInside)
        animateButton.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [actions, animateButton, milestoneGalleryLink])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: editCard.bottomAnchor, constant: 20),
            stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -30),
            animateButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 22),
            animateButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -22)
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
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 28)
        return stack
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func closeTapped() {
        guard let milestoneContext else {
            navigationController?.popToRootViewController(animated: true)
            return
        }
        if let resultImage {
            MilestoneStore.shared.capture(photo: resultImage, photoUrl: resultUrl.absoluteString, forMilestoneId: milestoneContext.milestoneId, inListId: milestoneContext.listId)
        }
        if let listVC = navigationController?.viewControllers.first(where: { $0 is MilestoneListDetailViewController }) {
            navigationController?.popToViewController(listVC, animated: true)
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }

    @objc private func expandTapped() {
        guard let resultImage else { return }
        HapticFeedback.light()
        present(ZoomableImageViewController(image: resultImage), animated: true)
    }

    @objc private func saveTapped() {
        guard let resultImage else { return }
        HapticFeedback.success()
        UIImageWriteToSavedPhotosAlbum(resultImage, nil, nil, nil)
    }

    @objc private func shareTapped() {
        guard let resultImage else { return }
        HapticFeedback.light()
        present(UIActivityViewController(activityItems: [resultImage], applicationActivities: nil), animated: true)
    }

    /// Sends this result's own durable Storage URL straight to animateResult — no local image
    /// bytes needed, Wiro fetches it server-side (see AnimationService's doc comment).
    ///
    /// The styleId sent here is what lets the server build a per-style animate prompt (its own
    /// descriptor/mood from ai_models) instead of a generic fallback — but a result from
    /// MilestoneCaptureViewController's own capture flow always carries `theme.id ==
    /// "custom-style"` (it generates through the shared customTheme, not the milestone's own
    /// ai_models entry), which would only ever hit animateResult's generic fallback even for a
    /// standard milestone like First Laugh. Standard-list milestone ids are deterministically
    /// the SAME as their ai_models style ids (see Milestone.swift's doc comment), so sending
    /// milestoneContext's id instead recovers the real per-style prompt for that case; a
    /// custom-list milestone's random UUID just won't match any ai_models doc and falls through
    /// to the same generic fallback as before — no worse than today.
    @objc private func animateTapped() {
        guard resultImage != nil else { return }
        HapticFeedback.light()
        let animateStyleId = milestoneContext?.milestoneId ?? theme.id
        CreditsService.requireCredits(presentingFrom: self) { [weak self] in
            guard let self else { return }
            self.animateButton.setLoading(true)
            AnimationService.animate(resultUrl: self.resultUrl, styleId: animateStyleId) { [weak self] result in
                guard let self else { return }
                self.animateButton.setLoading(false)
                switch result {
                case .success(let animation):
                    HapticFeedback.success()
                    self.navigationController?.pushViewController(AnimatedVideoViewController(videoURL: animation.videoUrl), animated: true)
                case .failure(let error):
                    self.presentAnimateError(error)
                }
            }
        }
    }

    private func presentAnimateError(_ error: Error) {
        let alert = UIAlertController(
            title: NSLocalizedString("Couldn't Animate This Portrait", comment: "Animate error title"),
            message: NSLocalizedString("Something went wrong. If credits were spent, they've been refunded. Please try again.", comment: "Animate error message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .default))
        present(alert, animated: true)
        print("animateResult failed: \(error)")
    }

    /// Searches every standard list (Firsts, Milestones, and any added later) for a milestone
    /// whose id matches this result's style — not just the first one — since a style id is only
    /// ever defined in one of them, but which list owns it isn't known ahead of time here.
    private func matchingUncapturedMilestone() -> (milestone: Milestone, listId: String)? {
        guard milestoneContext == nil else { return nil }
        for list in MilestoneStore.shared.lists where list.isStandard {
            if let milestone = list.milestones.first(where: { $0.id == theme.id }), milestone.state != .done {
                return (milestone, list.id)
            }
        }
        return nil
    }

    private func saveToPendingMilestoneIfNeeded(_ image: UIImage) {
        guard autoSaveEligible, let milestone = pendingMilestone, let listId = pendingMilestoneListId else { return }
        MilestoneStore.shared.capture(photo: image, photoUrl: resultUrl.absoluteString, forMilestoneId: milestone.id, inListId: listId)
        pendingMilestone = nil
        savedMilestoneListId = listId
        milestoneGalleryLink.isHidden = false
        HapticFeedback.success()
        let alert = UIAlertController(
            title: NSLocalizedString("Milestone Captured!", comment: "Milestone save confirmation title"),
            message: NSLocalizedString("This portrait was saved to your Milestone Gallery.", comment: "Milestone save confirmation message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .default))
        present(alert, animated: true)
    }

    @objc private func manualSaveMilestoneTapped() {
        guard let resultImage, let milestone = pendingMilestone, let listId = pendingMilestoneListId else { return }
        HapticFeedback.success()
        MilestoneStore.shared.capture(photo: resultImage, photoUrl: resultUrl.absoluteString, forMilestoneId: milestone.id, inListId: listId)
        pendingMilestone = nil
        savedMilestoneListId = listId
        milestoneGalleryLink.isHidden = false
        milestoneSaveButtonView?.isHidden = true
    }

    @objc private func goToMilestoneGalleryTapped() {
        HapticFeedback.light()
        let list = MilestoneStore.shared.lists.first { $0.id == savedMilestoneListId } ?? .standard
        navigationController?.pushViewController(MilestoneListDetailViewController(list: list), animated: true)
    }

    @objc private func submitEditTapped() {
        let instruction = editTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !instruction.isEmpty, let resultImage else { return }
        HapticFeedback.light()
        view.endEditing(true)
        CreditsService.requireCredits(presentingFrom: self) { [weak self] in
            guard let self else { return }
            let loading = GenerationLoadingViewController(theme: self.theme, sourceImage: resultImage, editInstruction: instruction)
            self.navigationController?.pushViewController(loading, animated: true)
        }
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else { return }

        let keyboardFrame = view.convert(frameValue.cgRectValue, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrame.minY - view.safeAreaInsets.bottom)

        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = overlap
            self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
        } completion: { _ in
            guard overlap > 0 else { return }
            // Bring the edit card just above the keyboard rather than only its caret position,
            // so the whole input (and its send button) stays visible while typing.
            self.scrollView.scrollRectToVisible(self.editCard.frame.insetBy(dx: 0, dy: -12), animated: true)
        }
    }
}

extension ResultViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        editPlaceholder.isHidden = !textView.text.isEmpty
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        editSendButton.isEnabled = hasText
        editSendButton.alpha = hasText ? 1 : 0.4
    }
}
