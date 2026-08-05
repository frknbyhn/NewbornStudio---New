import UIKit

/// Captures a milestone: pick a photo, optionally describe an AI touch-up. If the prompt is
/// left empty the picked photo is saved as-is — no Wiro call, no credits spent. If a prompt is
/// entered, it runs through the same generation scenario as "Create Your Own Style"
/// (`ai_models/custom-style` + editInstruction) and the AI result is saved instead.
/// For a standard-list milestone, the prompt field arrives pre-filled with that milestone's
/// curated `aiPrompt` — the user can keep it, edit it, or clear it back to a plain photo save.
final class MilestoneCaptureViewController: UIViewController {
    private static let customTheme = ThemeCard(id: "custom-style", name: "Custom Style", tint: Theme.Color.purpleBackground, previewImageUrl: nil)

    private let milestone: Milestone
    private let listId: String

    private var pickedImage: UIImage? {
        didSet { updatePreview() }
    }
    private let dropZone = UIView()
    private let dropStack = UIStackView()
    private let previewImageView = UIImageView()
    private var changePhotoLabel: UIView!
    private let promptTextView = UITextView()
    private let promptPlaceholder = UILabel()
    private let submitButton = GradientPillButton(title: "Save Photo", icon: UIImage(systemName: "checkmark.circle.fill"))

    init(milestone: Milestone, listId: String) {
        self.milestone = milestone
        self.listId = listId
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpNavBar()
        setUpContent()
        updateSubmitState()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    private var navBarBottom: NSLayoutYAxisAnchor!

    private func setUpNavBar() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        back.tintColor = Theme.Color.textSecondaryAlt
        back.backgroundColor = Theme.Color.backgroundWarm
        back.layer.cornerRadius = 12
        back.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        back.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = milestone.title
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
        dropTitle.text = "Add a photo for this moment"
        dropTitle.font = Theme.Font.heading(16, weight: 700)
        dropTitle.textColor = Theme.Color.textPrimaryAlt
        dropTitle.textAlignment = .center

        let dropSubtitle = UILabel()
        dropSubtitle.text = "JPG or PNG, up to 10 MB"
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
        changePhoto.text = "Tap to change photo"
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
        changePhotoLabel = changePhoto

        let promptTitle = UILabel()
        promptTitle.text = "Want an AI touch-up? (optional)"
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
        if let aiPrompt = milestone.aiPrompt, !aiPrompt.isEmpty {
            promptTextView.text = aiPrompt
        }

        promptPlaceholder.text = "e.g. \u{201c}Add soft golden light and floating sparkles\u{201d} — leave blank to just save the photo"
        promptPlaceholder.font = Theme.Font.body(14.5, weight: 600)
        promptPlaceholder.textColor = UIColor(hex: 0xB4A6A2)
        promptPlaceholder.numberOfLines = 0
        promptPlaceholder.isHidden = !promptTextView.text.isEmpty
        promptPlaceholder.translatesAutoresizingMaskIntoConstraints = false

        promptCard.addSubview(promptTextView)
        promptCard.addSubview(promptPlaceholder)

        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false

        let content = UIStackView(arrangedSubviews: [dropZone, promptTitle, promptCard, submitButton])
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

    private func updatePreview() {
        guard let pickedImage else {
            previewImageView.isHidden = true
            changePhotoLabel.isHidden = true
            dropStack.isHidden = false
            updateSubmitState()
            return
        }
        previewImageView.image = pickedImage
        previewImageView.isHidden = false
        changePhotoLabel.isHidden = false
        dropStack.isHidden = true
        updateSubmitState()
    }

    /// The button's title (not just its enabled state) reflects whether a prompt is present —
    /// an empty prompt means a plain photo save, a filled one means an AI generation is coming.
    private func updateSubmitState() {
        let hasPrompt = !promptTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        submitButton.title = hasPrompt ? "Generate & Save" : "Save Photo"
        submitButton.isEnabled = pickedImage != nil
        submitButton.alpha = submitButton.isEnabled ? 1 : 0.5
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func dropZoneTapped() {
        HapticFeedback.light()
        let alert = UIAlertController(title: "Add a Photo", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.presentPicker(sourceType: .camera)
        })
        alert.addAction(UIAlertAction(title: "Choose from Gallery", style: .default) { [weak self] _ in
            self?.presentPicker(sourceType: .photoLibrary)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func presentPicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func submitTapped() {
        guard let pickedImage else { return }
        let prompt = promptTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        HapticFeedback.light()
        view.endEditing(true)

        if prompt.isEmpty {
            MilestoneStore.shared.capture(photo: pickedImage, forMilestoneId: milestone.id, inListId: listId)
            HapticFeedback.success()
            navigationController?.popViewController(animated: true)
            return
        }

        CreditsService.requireCredits(presentingFrom: self) { [weak self] in
            guard let self else { return }
            let loading = GenerationLoadingViewController(theme: Self.customTheme, sourceImage: pickedImage, editInstruction: prompt) { [weak self] result in
                self?.saveGeneratedResult(result)
            }
            self.navigationController?.pushViewController(loading, animated: true)
        }
    }

    private func saveGeneratedResult(_ result: GenerationResult) {
        RemoteImageLoader.load(result.resultUrl) { [weak self] image in
            guard let self, let image else { return }
            MilestoneStore.shared.capture(photo: image, forMilestoneId: self.milestone.id, inListId: self.listId)
            HapticFeedback.success()
            if let listVC = self.navigationController?.viewControllers.first(where: { $0 is MilestoneListDetailViewController }) {
                self.navigationController?.popToViewController(listVC, animated: true)
            }
        }
    }
}

extension MilestoneCaptureViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

extension MilestoneCaptureViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        promptPlaceholder.isHidden = !textView.text.isEmpty
        updateSubmitState()
    }
}
