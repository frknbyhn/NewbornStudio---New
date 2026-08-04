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

    /// `sourceImage` is nil for a result opened from Gallery history — the original upload was
    /// never persisted (no Storage round-trip for source photos), only the AI result is kept.
    init(theme: ThemeCard, sourceImage: UIImage?, resultUrl: URL) {
        self.theme = theme
        self.sourceImage = sourceImage
        self.resultUrl = resultUrl
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItem?.tintColor = .white
        view.backgroundColor = UIColor(hex: 0x2E2530)
        setUpScrollContent()
        loadResultImage()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    /// This screen is the one place in the app with a real, visible UINavigationBar (every
    /// other pushed screen draws its own back button and keeps the tab's navigation bar
    /// hidden) — the close button needs to live in an actual nav bar per design, and doing
    /// that also sidesteps the z-order bug a floating overlay button had (it could end up
    /// underneath the scroll view depending on subview add order and go untappable).
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
        navigationController?.setNavigationBarHidden(true, animated: animated)
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
            content.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            // Content fills at least the visible area, so on a short result (small image) the
            // Save/Share row still ends up flush with the screen's bottom instead of floating
            // in the middle — see the flexible gap above `actions` in setUpActions().
            content.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor)
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

        editPlaceholder.text = "Want a change? Describe an edit — e.g. \u{201c}add a soft blue blanket\u{201d}"
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
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }

    private func setUpActions(in content: UIView) {
        let actions = UIStackView(arrangedSubviews: [
            actionButton(icon: "square.and.arrow.down", title: "Save", action: #selector(saveTapped)),
            actionButton(icon: "square.and.arrow.up", title: "Share", action: #selector(shareTapped))
        ])
        actions.axis = .horizontal
        actions.distribution = .equalSpacing
        actions.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(actions)

        NSLayoutConstraint.activate([
            // Flexible (>=) rather than fixed, so this row is free to sit lower — flush with
            // content's bottom — when content.heightAnchor stretches to fill a short screen.
            actions.topAnchor.constraint(greaterThanOrEqualTo: editCard.bottomAnchor, constant: 20),
            actions.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            actions.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -30)
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
        navigationController?.popToRootViewController(animated: true)
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
