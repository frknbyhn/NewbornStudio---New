import UIKit

/// Captures a milestone: just pick a photo. Standard milestones carry a curated `aiPrompt`, so
/// picking a photo there always runs the same generation scenario as "Create Your Own Style"
/// (`ai_models/custom-style` + editInstruction) — the result is shown on the normal
/// ResultViewController, and closing it (the X button) saves that result onto this milestone and
/// returns here instead of the default popToRoot (see ResultViewController.closeTapped).
/// Custom-list milestones have no curated prompt, so there's nothing to generate from — the
/// picked photo is saved directly, no Wiro call, no credits spent.
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
    private let submitButton: GradientPillButton

    init(milestone: Milestone, listId: String) {
        self.milestone = milestone
        self.listId = listId
        let hasPrompt = milestone.aiPrompt?.isEmpty == false
        self.submitButton = GradientPillButton(
            title: hasPrompt ? "Generate Portrait" : "Save Photo",
            icon: UIImage(systemName: hasPrompt ? "sparkles" : "checkmark.circle.fill")
        )
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

        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false

        let content = UIStackView(arrangedSubviews: [dropZone, submitButton])
        content.axis = .vertical
        content.spacing = 26
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 14, left: 22, bottom: 28, right: 22)
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: navBarBottom, constant: 10),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            dropZone.heightAnchor.constraint(equalToConstant: 260),
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
            changePhoto.heightAnchor.constraint(equalToConstant: 26)
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

    private func updateSubmitState() {
        submitButton.isEnabled = pickedImage != nil
        submitButton.alpha = submitButton.isEnabled ? 1 : 0.5
    }

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
        HapticFeedback.light()

        guard let prompt = milestone.aiPrompt, !prompt.isEmpty else {
            MilestoneStore.shared.capture(photo: pickedImage, forMilestoneId: milestone.id, inListId: listId)
            HapticFeedback.success()
            navigationController?.popViewController(animated: true)
            return
        }

        CreditsService.requireCredits(presentingFrom: self) { [weak self] in
            guard let self else { return }
            let context = MilestoneCaptureContext(milestoneId: self.milestone.id, listId: self.listId)
            let loading = GenerationLoadingViewController(theme: Self.customTheme, sourceImage: pickedImage, editInstruction: prompt, milestoneContext: context)
            self.navigationController?.pushViewController(loading, animated: true)
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
