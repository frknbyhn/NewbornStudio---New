import UIKit
import PhotosUI

final class PhotoUploadViewController: UIViewController {
    private let theme: ThemeCard
    private var pickedImage: UIImage?

    init(theme: ThemeCard) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
        // Stays hidden for every screen pushed after this one too (generation loading, result)
        // until the user pops back before this point in the stack.
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpNavBar()
        setUpContent()
        debugAutoGenerateIfNeeded()
    }

    private func debugAutoGenerateIfNeeded() {
        #if DEBUG
        // Screenshot/E2E-verification aid only — never reachable in a release build. Lets a
        // real generation be exercised end-to-end through the app's own code path (picker
        // delegate -> credits gate -> GenerationLoadingViewController -> GenerationService)
        // without needing tap automation to drive UIImagePickerController. Pulls the most
        // recently added photo from the simulator's own library (seeded via
        // `simctl addmedia`) rather than reading a host file path — the app's sandbox can't
        // see arbitrary host paths, but PHPhotoLibrary works exactly like on a real device.
        guard ProcessInfo.processInfo.environment["NS_DEBUG_AUTO_GENERATE"] != nil else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            // Bypasses FaceCheck deliberately — the synthetic image has no real face, and this
            // path exists to verify the network pipeline, not face-detection behavior.
            self.pickedImage = self.debugSyntheticPhoto()
            self.proceedAfterFaceCheck(self.pickedImage!)
        }
        #endif
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
        title.text = NSLocalizedString("Upload a photo", comment: "Photo upload screen nav title")
        title.font = Theme.Font.heading(19, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt

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
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22)
        ])
        navBarBottom = bar.bottomAnchor
    }

    private var navBarBottom: NSLayoutYAxisAnchor!

    private func setUpContent() {
        let dropZone = UIView()
        dropZone.backgroundColor = UIColor(hex: 0xFFF4F1)
        dropZone.layer.cornerRadius = 26
        dropZone.layer.borderWidth = 2
        dropZone.layer.borderColor = UIColor(hex: 0xEBC3CC).cgColor
        dropZone.isUserInteractionEnabled = true
        dropZone.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dropZoneTapped)))

        let circle = UIView()
        circle.backgroundColor = .white
        circle.layer.cornerRadius = 38
        let cameraIcon = UIImageView(image: UIImage(systemName: "camera.fill"))
        cameraIcon.tintColor = Theme.Color.accentEnd
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(cameraIcon)
        circle.translatesAutoresizingMaskIntoConstraints = false

        let dropTitle = UILabel()
        dropTitle.text = NSLocalizedString("Upload a clear photo of your baby", comment: "Photo upload drop zone title")
        dropTitle.font = Theme.Font.heading(16, weight: 700)
        dropTitle.textColor = Theme.Color.textPrimaryAlt
        dropTitle.textAlignment = .center
        dropTitle.numberOfLines = 0

        let dropSubtitle = UILabel()
        dropSubtitle.text = NSLocalizedString("JPG or PNG, up to 10 MB", comment: "Photo upload drop zone subtitle")
        dropSubtitle.font = Theme.Font.body(13, weight: 500)
        dropSubtitle.textColor = Theme.Color.textSecondary
        dropSubtitle.textAlignment = .center

        let dropStack = UIStackView(arrangedSubviews: [circle, dropTitle, dropSubtitle])
        dropStack.axis = .vertical
        dropStack.alignment = .center
        dropStack.spacing = 14
        dropStack.isLayoutMarginsRelativeArrangement = true
        dropStack.layoutMargins = UIEdgeInsets(top: 40, left: 24, bottom: 40, right: 24)
        dropStack.translatesAutoresizingMaskIntoConstraints = false
        dropZone.addSubview(dropStack)
        dropZone.translatesAutoresizingMaskIntoConstraints = false

        let tipsTitle = UILabel()
        tipsTitle.text = NSLocalizedString("For the best results", comment: "Photo upload tips title")
        tipsTitle.font = Theme.Font.heading(14, weight: 700)
        tipsTitle.textColor = Theme.Color.textSecondaryAlt

        let tips = UIStackView(arrangedSubviews: [
            tipRow(icon: "sun.max.fill", iconColor: Theme.Color.coin, iconBg: Theme.Color.coinBackground, text: NSLocalizedString("Bright, even lighting", comment: "Photo upload tip")),
            tipRow(icon: "face.smiling.fill", iconColor: Theme.Color.success, iconBg: Theme.Color.successBackground, text: NSLocalizedString("Face clearly visible", comment: "Photo upload tip")),
            tipRow(icon: "nosign", iconColor: Theme.Color.purpleAccent, iconBg: Theme.Color.purpleBackground, text: NSLocalizedString("No filters or heavy edits", comment: "Photo upload tip"))
        ])
        tips.axis = .vertical
        tips.spacing = 12

        let takePhoto = GradientPillButton(title: NSLocalizedString("Take Photo", comment: "Photo upload button"), icon: UIImage(systemName: "camera.fill"))
        takePhoto.addTarget(self, action: #selector(takePhotoTapped), for: .touchUpInside)

        let chooseGallery = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("Choose from Gallery", comment: "Photo upload button")
        config.image = UIImage(systemName: "photo")
        config.imagePadding = 8
        config.baseBackgroundColor = Theme.Color.backgroundWarm
        config.baseForegroundColor = Theme.Color.textSecondaryAlt
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString(NSLocalizedString("Choose from Gallery", comment: "Photo upload button"), attributes: .init([.font: Theme.Font.heading(16, weight: 700)]))
        chooseGallery.configuration = config
        chooseGallery.addTarget(self, action: #selector(chooseGalleryTapped), for: .touchUpInside)
        chooseGallery.translatesAutoresizingMaskIntoConstraints = false
        chooseGallery.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let content = UIStackView(arrangedSubviews: [dropZone, tipsTitle, tips])
        content.axis = .vertical
        content.spacing = 22
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 12, left: 22, bottom: 0, right: 22)
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)

        let actions = UIStackView(arrangedSubviews: [takePhoto, chooseGallery])
        actions.axis = .vertical
        actions.spacing = 12
        actions.isLayoutMarginsRelativeArrangement = true
        actions.layoutMargins = UIEdgeInsets(top: 0, left: 22, bottom: 24, right: 22)
        actions.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actions)

        NSLayoutConstraint.activate([
            cameraIcon.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            circle.widthAnchor.constraint(equalToConstant: 76),
            circle.heightAnchor.constraint(equalToConstant: 76),
            dropStack.topAnchor.constraint(equalTo: dropZone.topAnchor),
            dropStack.leadingAnchor.constraint(equalTo: dropZone.leadingAnchor),
            dropStack.trailingAnchor.constraint(equalTo: dropZone.trailingAnchor),
            dropStack.bottomAnchor.constraint(equalTo: dropZone.bottomAnchor),

            content.topAnchor.constraint(equalTo: navBarBottom, constant: 12),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            actions.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actions.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actions.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
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

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    #if DEBUG
    /// A synthetic in-process photo — `simctl addmedia` is unreliable on this host, and the
    /// app's sandbox can't read an arbitrary host file path, so this avoids both: it's a real
    /// UIImage going through the exact same GenerationService.generate() call a real photo
    /// would, which is what actually needs verifying end-to-end (not photo realism).
    private func debugSyntheticPhoto() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 640, height: 854))
        return renderer.image { ctx in
            UIColor(hex: 0xE8C9A8).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 640, height: 854))
            UIColor.white.withAlphaComponent(0.85).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 170, y: 300, width: 300, height: 300))
        }
    }
    #endif

    @objc private func takePhotoTapped() {
        HapticFeedback.light()
        presentPicker(sourceType: .camera)
    }

    @objc private func chooseGalleryTapped() {
        HapticFeedback.light()
        presentPicker(sourceType: .photoLibrary)
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
}

extension PhotoUploadViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        proceedWithPickedImage(image)
    }

    fileprivate func proceedWithPickedImage(_ image: UIImage) {
        pickedImage = image
        FaceCheck.run(on: image, presentingFrom: self) { [weak self] in
            self?.proceedAfterFaceCheck(image)
        }
    }

    fileprivate func proceedAfterFaceCheck(_ image: UIImage) {
        // Gate right here — the moment generation is actually requested — rather than
        // earlier at style-selection, so it reflects real-time credit/subscription state.
        CreditsService.requireCredits(presentingFrom: self) { [weak self] in
            guard let self else { return }
            let loading = GenerationLoadingViewController(theme: self.theme, sourceImage: image)
            self.navigationController?.pushViewController(loading, animated: true)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
