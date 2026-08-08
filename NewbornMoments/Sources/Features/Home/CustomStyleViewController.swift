import UIKit

/// "Create Your Own Style" — collects a photo + a free-form prompt and runs the exact same
/// generation scenario as a catalog style (credits gate -> GenerationLoadingViewController ->
/// ResultViewController), just with `editInstruction` standing in for a fixed style prompt.
/// `styleId` points at the reserved `ai_models/custom-style` doc (functions/seedCustomStyle.js)
/// — its own `prompt` field is never used since editInstruction always takes precedence server-side.
final class CustomStyleViewController: UIViewController {
    private static let customTheme = ThemeCard(id: "custom-style", name: NSLocalizedString("Custom Style", comment: "Custom-style theme name"), tint: Theme.Color.purpleBackground, previewImageUrl: nil)

    private var pickedImage: UIImage? {
        didSet { updatePreview() }
    }
    private let dropZone = UIView()
    private let dropStack = UIStackView()
    private let previewImageView = UIImageView()
    private let promptTextView = UITextView()
    private let promptPlaceholder = UILabel()
    private let generateButton = GradientPillButton(title: NSLocalizedString("Generate", comment: "Custom style generate button"), icon: UIImage(systemName: "sparkles"))

    init() {
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpNavBar()
        setUpContent()
        updateGenerateEnabled()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    private func setUpNavBar() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        back.tintColor = Theme.Color.textSecondaryAlt
        back.backgroundColor = Theme.Color.backgroundWarm
        back.layer.cornerRadius = 12
        back.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        back.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = NSLocalizedString("Create Your Own Style", comment: "Custom style screen nav title")
        title.font = Theme.Font.heading(19, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.numberOfLines = 1
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.8

        let bar = UIStackView(arrangedSubviews: [back, title])
        bar.axis = .horizontal
        bar.spacing = 14
        bar.alignment = .center
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)

        NSLayoutConstraint.activate([
            back.widthAnchor.constraint(equalToConstant: 38),
            back.heightAnchor.constraint(equalToConstant: 38),
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            bar.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -22)
        ])
        navBarBottom = bar.bottomAnchor
    }

    private var navBarBottom: NSLayoutYAxisAnchor!

    private func setUpContent() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)

        dropZone.backgroundColor = UIColor(hex: 0xFFF4F1)
        dropZone.layer.cornerRadius = 26
        dropZone.layer.borderWidth = 2
        dropZone.layer.borderColor = UIColor(hex: 0xEBC3CC).cgColor
        dropZone.layer.masksToBounds = true
        dropZone.translatesAutoresizingMaskIntoConstraints = false
        dropZone.isUserInteractionEnabled = true
        dropZone.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dropZoneTapped)))

        let circle = UIView()
        circle.backgroundColor = .white
        circle.layer.cornerRadius = 38
        circle.translatesAutoresizingMaskIntoConstraints = false
        let cameraIcon = UIImageView(image: UIImage(systemName: "photo.badge.plus"))
        cameraIcon.tintColor = Theme.Color.accentEnd
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(cameraIcon)

        let dropTitle = UILabel()
        dropTitle.text = NSLocalizedString("Add a photo to start from", comment: "Custom style drop zone title")
        dropTitle.font = Theme.Font.heading(16, weight: 700)
        dropTitle.textColor = Theme.Color.textPrimaryAlt
        dropTitle.textAlignment = .center

        let dropSubtitle = UILabel()
        dropSubtitle.text = NSLocalizedString("JPG or PNG, up to 10 MB", comment: "Custom style drop zone subtitle")
        dropSubtitle.font = Theme.Font.body(13, weight: 500)
        dropSubtitle.textColor = Theme.Color.textSecondary
        dropSubtitle.textAlignment = .center

        dropStack.axis = .vertical
        dropStack.alignment = .center
        dropStack.spacing = 14
        dropStack.isLayoutMarginsRelativeArrangement = true
        dropStack.layoutMargins = UIEdgeInsets(top: 36, left: 24, bottom: 36, right: 24)
        dropStack.translatesAutoresizingMaskIntoConstraints = false
        dropStack.addArrangedSubview(circle)
        dropStack.addArrangedSubview(dropTitle)
        dropStack.addArrangedSubview(dropSubtitle)
        dropZone.addSubview(dropStack)

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.isHidden = true
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        dropZone.addSubview(previewImageView)

        let changePhoto = PaddedLabel()
        changePhoto.text = NSLocalizedString("Tap to change photo", comment: "Custom style photo overlay label")
        changePhoto.horizontalPadding = 12
        changePhoto.font = Theme.Font.heading(11, weight: 700)
        changePhoto.textColor = .white
        changePhoto.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        changePhoto.layer.cornerRadius = 12
        changePhoto.layer.masksToBounds = true
        changePhoto.textAlignment = .center
        changePhoto.isHidden = true
        changePhoto.translatesAutoresizingMaskIntoConstraints = false
        dropZone.addSubview(changePhoto)
        self.changePhotoLabel = changePhoto

        let promptTitle = UILabel()
        promptTitle.text = NSLocalizedString("Describe your idea", comment: "Custom style prompt field label")
        promptTitle.font = Theme.Font.heading(14, weight: 700)
        promptTitle.textColor = Theme.Color.textSecondaryAlt

        let promptCard = UIView()
        promptCard.backgroundColor = .white
        promptCard.layer.cornerRadius = 18
        promptCard.layer.borderWidth = 1.5
        promptCard.layer.borderColor = UIColor(hex: 0xEEE3DB).cgColor
        promptCard.translatesAutoresizingMaskIntoConstraints = false

        promptTextView.backgroundColor = .clear
        promptTextView.textColor = Theme.Color.textPrimaryAlt
        promptTextView.tintColor = Theme.Color.accentEnd
        promptTextView.font = Theme.Font.body(14.5, weight: 600)
        promptTextView.isScrollEnabled = false
        promptTextView.textContainerInset = .zero
        promptTextView.textContainer.lineFragmentPadding = 0
        promptTextView.delegate = self
        promptTextView.translatesAutoresizingMaskIntoConstraints = false

        promptPlaceholder.text = NSLocalizedString("e.g. \u{201c}Turn my baby into a tiny astronaut floating among the stars\u{201d}", comment: "Custom style prompt field placeholder")
        promptPlaceholder.font = Theme.Font.body(14.5, weight: 600)
        promptPlaceholder.textColor = UIColor(hex: 0xB4A6A2)
        promptPlaceholder.numberOfLines = 0
        promptPlaceholder.translatesAutoresizingMaskIntoConstraints = false

        promptCard.addSubview(promptTextView)
        promptCard.addSubview(promptPlaceholder)

        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        generateButton.translatesAutoresizingMaskIntoConstraints = false

        let content = UIStackView(arrangedSubviews: [dropZone, promptTitle, promptCard, generateButton])
        content.axis = .vertical
        content.spacing = 16
        content.setCustomSpacing(10, after: promptTitle)
        content.setCustomSpacing(26, after: promptCard)
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 14, left: 22, bottom: 28, right: 22)
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: navBarBottom, constant: 10),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor),

            dropZone.heightAnchor.constraint(equalToConstant: 220),
            dropStack.topAnchor.constraint(equalTo: dropZone.topAnchor),
            dropStack.leadingAnchor.constraint(equalTo: dropZone.leadingAnchor),
            dropStack.trailingAnchor.constraint(equalTo: dropZone.trailingAnchor),
            dropStack.bottomAnchor.constraint(equalTo: dropZone.bottomAnchor),
            circle.widthAnchor.constraint(equalToConstant: 76),
            circle.heightAnchor.constraint(equalToConstant: 76),
            cameraIcon.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: circle.centerYAnchor),

            previewImageView.topAnchor.constraint(equalTo: dropZone.topAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: dropZone.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: dropZone.trailingAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: dropZone.bottomAnchor),
            changePhoto.centerXAnchor.constraint(equalTo: dropZone.centerXAnchor),
            changePhoto.bottomAnchor.constraint(equalTo: dropZone.bottomAnchor, constant: -14),
            changePhoto.heightAnchor.constraint(equalToConstant: 26),

            promptCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            promptTextView.topAnchor.constraint(equalTo: promptCard.topAnchor, constant: 14),
            promptTextView.leadingAnchor.constraint(equalTo: promptCard.leadingAnchor, constant: 14),
            promptTextView.trailingAnchor.constraint(equalTo: promptCard.trailingAnchor, constant: -14),
            promptTextView.bottomAnchor.constraint(lessThanOrEqualTo: promptCard.bottomAnchor, constant: -14),
            promptPlaceholder.topAnchor.constraint(equalTo: promptTextView.topAnchor),
            promptPlaceholder.leadingAnchor.constraint(equalTo: promptTextView.leadingAnchor),
            promptPlaceholder.trailingAnchor.constraint(equalTo: promptTextView.trailingAnchor)
        ])
    }

    private var changePhotoLabel: UIView!

    private func updatePreview() {
        guard let pickedImage else {
            previewImageView.isHidden = true
            changePhotoLabel.isHidden = true
            dropStack.isHidden = false
            return
        }
        previewImageView.image = pickedImage
        previewImageView.isHidden = false
        changePhotoLabel.isHidden = false
        dropStack.isHidden = true
        updateGenerateEnabled()
    }

    private func updateGenerateEnabled() {
        let hasPrompt = !promptTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        generateButton.isEnabled = pickedImage != nil && hasPrompt
        generateButton.alpha = generateButton.isEnabled ? 1 : 0.5
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func dropZoneTapped() {
        HapticFeedback.light()
        let alert = UIAlertController(title: NSLocalizedString("Add a Photo", comment: "Photo source action sheet title"), message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Take Photo", comment: "Photo source action"), style: .default) { [weak self] _ in
            self?.presentPicker(sourceType: .camera)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Choose from Gallery", comment: "Photo source action"), style: .default) { [weak self] _ in
            self?.presentPicker(sourceType: .photoLibrary)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: .cancel))
        present(alert, animated: true)
    }

    private func presentPicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func generateTapped() {
        guard let pickedImage else { return }
        let prompt = promptTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        HapticFeedback.light()
        view.endEditing(true)
        CreditsService.requireCredits(presentingFrom: self) { [weak self] in
            guard let self else { return }
            let loading = GenerationLoadingViewController(theme: Self.customTheme, sourceImage: pickedImage, editInstruction: prompt)
            self.navigationController?.pushViewController(loading, animated: true)
        }
    }
}

extension CustomStyleViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        FaceCheck.run(on: image, presentingFrom: self) { [weak self] in
            self?.pickedImage = image
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension CustomStyleViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        promptPlaceholder.isHidden = !textView.text.isEmpty
        updateGenerateEnabled()
    }
}
