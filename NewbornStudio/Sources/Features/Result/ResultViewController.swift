import UIKit

final class ResultViewController: UIViewController {
    private let theme: ThemeCard
    private let sourceImage: UIImage
    private var resultUrl: URL
    private var resultImage: UIImage?
    private let resultImageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let editTextView = UITextView()
    private let editPlaceholder = UILabel()
    private let editSendButton = UIButton(type: .system)

    init(theme: ThemeCard, sourceImage: UIImage, resultUrl: URL) {
        self.theme = theme
        self.sourceImage = sourceImage
        self.resultUrl = resultUrl
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        view.backgroundColor = UIColor(hex: 0x2E2530)
        setUpTopBar()
        setUpImage()
        setUpEditBox()
        setUpActions()
        loadResultImage()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    private func setUpTopBar() {
        let close = circleButton(icon: "xmark")
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        view.addSubview(close)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22)
        ])
        topBarBottom = close.bottomAnchor
    }

    private var topBarBottom: NSLayoutYAxisAnchor!

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

    private func setUpImage() {
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

        let watermark = UILabel()
        watermark.text = "Newborn Studio"
        watermark.font = Theme.Font.heading(12, weight: 700)
        watermark.textColor = UIColor.white.withAlphaComponent(0.45)
        watermark.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(watermark)

        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topBarBottom, constant: 6),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),

            resultImageView.topAnchor.constraint(equalTo: container.topAnchor),
            resultImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            resultImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            resultImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            watermark.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
            watermark.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        imageContainer = container
    }

    private var imageContainer: UIView!

    /// Themed text input for requesting an edit on the just-generated result — submitting sends
    /// this image + instruction back through the same generation scenario (GenerationLoadingViewController).
    private func setUpEditBox() {
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
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),

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
        editCardBottom = card.bottomAnchor
    }

    private var editCardBottom: NSLayoutYAxisAnchor!

    private func loadResultImage() {
        URLSession.shared.dataTask(with: resultUrl) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.spinner.stopAnimating()
                if let data, let image = UIImage(data: data) {
                    self.resultImage = image
                    self.resultImageView.image = image
                } else {
                    // Real network failure state, not a silent blank — matches the offline-state rule.
                    print("Failed to load result image: \(error?.localizedDescription ?? "unknown error")")
                    self.resultImageView.image = self.sourceImage
                }
            }
        }.resume()
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
            actions.topAnchor.constraint(equalTo: editCardBottom, constant: 20),
            actions.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actions.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
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
}

extension ResultViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        editPlaceholder.isHidden = !textView.text.isEmpty
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        editSendButton.isEnabled = hasText
        editSendButton.alpha = hasText ? 1 : 0.4
    }
}
