import UIKit

/// Captures a milestone: pick a photo, then either generate an AI portrait from it or save it
/// as-is, depending on where the prompt comes from.
///
/// - Standard milestones carry a curated `aiPrompt` — no prompt UI at all, picking a photo
///   always generates using that prompt (nothing external to ask the user for).
/// - Custom-list milestones have no curated prompt, so an optional prompt textview is shown: a
///   filled-in prompt runs the same generation scenario as "Create Your Own Style"
///   (`ai_models/custom-style` + editInstruction, 1 credit); left empty, the picked photo is
///   just saved directly — no Wiro call, no credits spent.
///
/// Either way, a generation's result is shown on the normal ResultViewController, and closing it
/// (the X button) saves that result onto this milestone and returns here instead of the default
/// popToRoot (see ResultViewController.closeTapped).
final class MilestoneCaptureViewController: UIViewController {
    private static let customTheme = ThemeCard(id: "custom-style", name: NSLocalizedString("Custom Style", comment: "Custom-style theme name"), tint: Theme.Color.purpleBackground, previewImageUrl: nil)

    private let milestone: Milestone
    private let listId: String
    private let curatedPrompt: String?

    private var pickedImage: UIImage? {
        didSet { updatePreview() }
    }
    private let dropZone = UIView()
    private let dropStack = UIStackView()
    private let previewImageView = UIImageView()
    private var changePhotoLabel: UIView!
    private let promptTextView = UITextView()
    private let promptPlaceholder = UILabel()
    private let submitButton: GradientPillButton

    init(milestone: Milestone, listId: String) {
        self.milestone = milestone
        self.listId = listId
        let curatedPrompt = milestone.aiPrompt?.isEmpty == false ? milestone.aiPrompt : nil
        self.curatedPrompt = curatedPrompt
        self.submitButton = GradientPillButton(
            title: curatedPrompt != nil ? NSLocalizedString("Generate Portrait", comment: "Milestone capture submit button") : NSLocalizedString("Save Photo", comment: "Milestone capture submit button"),
            icon: UIImage(systemName: curatedPrompt != nil ? "sparkles" : "checkmark.circle.fill")
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

        if curatedPrompt == nil {
            let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            // Without this, the recognizer (added straight to `view`, above every subview in the
            // hit-test order) steals every single tap — including ones landing on the submit
            // button — before UIControl ever sees a touchUpInside. Mirrors the same fix already
            // in place on ResultViewController's identical dismiss-keyboard gesture.
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshRecentPhotosStrip()
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
        dropTitle.text = NSLocalizedString("Add a photo for this moment", comment: "Milestone capture drop zone title")
        dropTitle.font = Theme.Font.heading(16, weight: 700)
        dropTitle.textColor = Theme.Color.textPrimaryAlt
        dropTitle.textAlignment = .center

        let dropSubtitle = UILabel()
        dropSubtitle.text = NSLocalizedString("JPG or PNG, up to 10 MB", comment: "Photo drop zone subtitle")
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
        
        let tipsTitle = UILabel()
        tipsTitle.text = NSLocalizedString("For the best results", comment: "Photo tips title")
        tipsTitle.font = Theme.Font.heading(14, weight: 700)
        tipsTitle.textColor = Theme.Color.textSecondaryAlt

        let tips = UIStackView(arrangedSubviews: [
            tipRow(icon: "sun.max.fill", iconColor: Theme.Color.coin, iconBg: Theme.Color.coinBackground, text: NSLocalizedString("Bright, even lighting", comment: "Photo tip")),
            tipRow(icon: "face.smiling.fill", iconColor: Theme.Color.success, iconBg: Theme.Color.successBackground, text: NSLocalizedString("Face clearly visible", comment: "Photo tip")),
            tipRow(icon: "nosign", iconColor: Theme.Color.purpleAccent, iconBg: Theme.Color.purpleBackground, text: NSLocalizedString("No filters or heavy edits", comment: "Photo tip"))
        ])
        tips.axis = .vertical
        tips.spacing = 12

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.isHidden = true
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        dropZone.addSubview(previewImageView)

        let changePhoto = PaddedLabel()
        changePhoto.text = NSLocalizedString("Tap to change photo", comment: "Photo overlay label")
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

        let recentStrip = makeRecentPhotosStrip()

        var arranged: [UIView] = [dropZone, recentStrip, tips]
        var promptCard: UIView?
        if curatedPrompt == nil {
            let promptTitle = UILabel()
            promptTitle.text = NSLocalizedString("Want an AI touch-up? (optional)", comment: "Milestone capture prompt field label")
            promptTitle.font = Theme.Font.heading(14, weight: 700)
            promptTitle.textColor = Theme.Color.textSecondaryAlt

            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 18
            card.layer.borderWidth = 1.5
            card.layer.borderColor = UIColor(hex: 0xEEE3DB).cgColor
            card.translatesAutoresizingMaskIntoConstraints = false

            promptTextView.backgroundColor = .clear
            promptTextView.textColor = Theme.Color.textPrimaryAlt
            promptTextView.tintColor = Theme.Color.accentEnd
            promptTextView.font = Theme.Font.body(14.5, weight: 600)
            promptTextView.isScrollEnabled = false
            promptTextView.textContainerInset = .zero
            promptTextView.textContainer.lineFragmentPadding = 0
            promptTextView.delegate = self
            promptTextView.translatesAutoresizingMaskIntoConstraints = false

            promptPlaceholder.text = NSLocalizedString("e.g. \u{201c}Add soft golden light and floating sparkles\u{201d} — leave blank to just save the photo", comment: "Milestone capture prompt placeholder")
            promptPlaceholder.font = Theme.Font.body(14.5, weight: 600)
            promptPlaceholder.textColor = UIColor(hex: 0xB4A6A2)
            promptPlaceholder.numberOfLines = 0
            promptPlaceholder.translatesAutoresizingMaskIntoConstraints = false

            card.addSubview(promptTextView)
            card.addSubview(promptPlaceholder)
            NSLayoutConstraint.activate([
                card.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
                promptTextView.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                promptTextView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
                promptTextView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
                promptTextView.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -14),
                promptPlaceholder.topAnchor.constraint(equalTo: promptTextView.topAnchor),
                promptPlaceholder.leadingAnchor.constraint(equalTo: promptTextView.leadingAnchor),
                promptPlaceholder.trailingAnchor.constraint(equalTo: promptTextView.trailingAnchor)
            ])

            arranged.append(promptTitle)
            arranged.append(card)
            promptCard = card
        }
        arranged.append(submitButton)

        let content = UIStackView(arrangedSubviews: arranged)
        content.axis = .vertical
        content.spacing = 16
        if let promptCard {
            content.setCustomSpacing(10, after: tips)
            content.setCustomSpacing(26, after: promptCard)
        } else {
            content.setCustomSpacing(26, after: dropZone)
        }
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
            changePhoto.heightAnchor.constraint(equalToConstant: 26)
        ])
    }

    private func tipRow(icon: String, iconColor: UIColor, iconBg: UIColor, text: String) -> UIView {
        let bg = UIView()
        bg.backgroundColor = iconBg
        bg.layer.cornerRadius = 10
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.widthAnchor.constraint(equalToConstant: 34).isActive = true
        bg.heightAnchor.constraint(equalToConstant: 34).isActive = true

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = iconColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: bg.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: bg.centerYAnchor)
        ])

        let label = UILabel()
        label.text = text
        label.font = Theme.Font.body(14, weight: 600)
        label.textColor = Theme.Color.textSecondaryAlt

        let row = UIStackView(arrangedSubviews: [bg, label])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        return row
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
        if curatedPrompt == nil {
            let hasPrompt = !promptTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            submitButton.title = hasPrompt ? NSLocalizedString("Generate & Save", comment: "Milestone capture submit button") : NSLocalizedString("Save Photo", comment: "Milestone capture submit button")
        }
        submitButton.isEnabled = pickedImage != nil
        submitButton.alpha = submitButton.isEnabled ? 1 : 0.5
    }

    // MARK: - Recently used photos

    private var recentStripContainer: UIView!
    private var recentStripStack: UIStackView!
    private var selectedRecentPhotoId: String?

    private func makeRecentPhotosStrip() -> UIView {
        let title = UILabel()
        title.text = NSLocalizedString("Recently Used", comment: "Recently used photos section title")
        title.font = Theme.Font.heading(14, weight: 700)
        title.textColor = Theme.Color.textSecondaryAlt

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        recentStripStack = stack

        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scroll.heightAnchor),
            scroll.heightAnchor.constraint(equalToConstant: 76)
        ])

        let container = UIStackView(arrangedSubviews: [title, scroll])
        container.axis = .vertical
        container.spacing = 10
        recentStripContainer = container
        return container
    }

    private func refreshRecentPhotosStrip() {
        recentStripStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let photos = RecentPhotosStore.recentPhotos()
        recentStripContainer.isHidden = photos.isEmpty
        for photo in photos {
            let cell = RecentPhotoCell(photo: photo, isSelected: photo.id == selectedRecentPhotoId)
            cell.onSelect = { [weak self] in self?.recentPhotoSelected(photo) }
            cell.onDelete = { [weak self] in self?.recentPhotoDeleted(photo) }
            recentStripStack.addArrangedSubview(cell)
        }
    }

    /// Only puts the photo into the drop zone preview — does NOT submit. The user still has to
    /// tap Generate/Save, same as a fresh camera/gallery pick.
    private func recentPhotoSelected(_ photo: RecentPhotosStore.Photo) {
        HapticFeedback.selection()
        selectedRecentPhotoId = photo.id
        pickedImage = photo.image
        RecentPhotosStore.moveToFront(id: photo.id)
        refreshRecentPhotosStrip()
    }

    private func recentPhotoDeleted(_ photo: RecentPhotosStore.Photo) {
        HapticFeedback.light()
        RecentPhotosStore.remove(id: photo.id)
        if selectedRecentPhotoId == photo.id {
            selectedRecentPhotoId = nil
        }
        refreshRecentPhotosStrip()
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

    @objc private func submitTapped() {
        guard let pickedImage else { return }
        HapticFeedback.light()
        view.endEditing(true)

        let prompt = curatedPrompt ?? promptTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            MilestoneStore.shared.capture(photo: pickedImage, forMilestoneId: milestone.id, inListId: listId)
            HapticFeedback.success()
            navigationController?.popViewController(animated: true)
            return
        }

        CreditsService.requireCredits(presentingFrom: self) { [weak self] in
            guard let self else { return }
            let context = MilestoneCaptureContext(milestoneId: self.milestone.id, listId: self.listId)
            // true whenever this is a curated milestone prompt (not the user's own free-typed
            // one) — the whole point of a milestone like First Laugh or Waves Bye-Bye IS a
            // different expression/pose than the uploaded photo, so the default "preserve the
            // original expression" instruction can't be allowed to override it. See
            // GenerationService.generate's doc comment.
            let loading = GenerationLoadingViewController(theme: Self.customTheme, sourceImage: pickedImage, editInstruction: prompt, allowPoseChange: self.curatedPrompt != nil, milestoneContext: context)
            self.navigationController?.pushViewController(loading, animated: true)
        }
    }
}

extension MilestoneCaptureViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        selectedRecentPhotoId = nil
        FaceCheck.run(on: image, presentingFrom: self) { [weak self] in
            guard let self else { return }
            self.pickedImage = image
            RecentPhotosStore.add(image)
            self.refreshRecentPhotosStrip()
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
