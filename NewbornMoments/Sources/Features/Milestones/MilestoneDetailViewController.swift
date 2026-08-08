import UIKit

/// Detail/edit screen for an already-captured milestone — reachable by tapping a "Captured" row
/// in MilestoneListDetailViewController. Shows the photo, which list it belongs to, and the
/// milestone's own name; lets the user replace the photo or delete the capture entirely. Either
/// change writes through MilestoneStore (so it's persisted and reflected the moment this screen
/// pops back to the list, which reloads from the store on every appearance).
final class MilestoneDetailViewController: UIViewController {
    private let milestone: Milestone
    private let listId: String
    private let photoImageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(milestone: Milestone, listId: String) {
        self.milestone = milestone
        self.listId = listId
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var listName: String {
        MilestoneStore.shared.lists.first { $0.id == listId }?.name ?? ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpNavBar()
        setUpContent()
        loadPhoto()
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

        let photoContainer = UIView()
        photoContainer.backgroundColor = UIColor(hex: 0xEDE0D8)
        photoContainer.layer.cornerRadius = 26
        photoContainer.layer.masksToBounds = true
        photoContainer.translatesAutoresizingMaskIntoConstraints = false

        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoContainer.addSubview(photoImageView)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        photoContainer.addSubview(spinner)

        let changePhoto = PaddedLabel()
        changePhoto.text = "Tap to change photo"
        changePhoto.horizontalPadding = 12
        changePhoto.font = Theme.Font.heading(11, weight: 700)
        changePhoto.textColor = .white
        changePhoto.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        changePhoto.layer.cornerRadius = 12
        changePhoto.layer.masksToBounds = true
        changePhoto.textAlignment = .center
        changePhoto.translatesAutoresizingMaskIntoConstraints = false
        photoContainer.addSubview(changePhoto)

        photoContainer.isUserInteractionEnabled = true
        photoContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changePhotoTapped)))

        let infoCard = UIView()
        infoCard.backgroundColor = .white
        infoCard.layer.cornerRadius = 18
        infoCard.translatesAutoresizingMaskIntoConstraints = false

        let infoStack = UIStackView(arrangedSubviews: [infoRow(label: "List", value: listName), infoRow(label: "Milestone", value: milestone.title)])
        infoStack.axis = .vertical
        infoStack.spacing = 14
        infoStack.isLayoutMarginsRelativeArrangement = true
        infoStack.layoutMargins = UIEdgeInsets(top: 16, left: 18, bottom: 16, right: 18)
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(infoStack)
        NSLayoutConstraint.activate([
            infoStack.topAnchor.constraint(equalTo: infoCard.topAnchor),
            infoStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            infoStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            infoStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor)
        ])

        let changePhotoButton = UIButton(type: .system)
        var changeConfig = UIButton.Configuration.plain()
        changeConfig.title = "Change Photo"
        changeConfig.image = UIImage(systemName: "photo.badge.plus")
        changeConfig.imagePadding = 8
        changeConfig.baseForegroundColor = Theme.Color.accentEnd
        changeConfig.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        changePhotoButton.configuration = changeConfig
        changePhotoButton.titleLabel?.font = Theme.Font.heading(15, weight: 700)
        changePhotoButton.backgroundColor = .white
        changePhotoButton.layer.cornerRadius = 18
        changePhotoButton.layer.borderWidth = 1.5
        changePhotoButton.layer.borderColor = UIColor(hex: 0xE5D2C7).cgColor
        changePhotoButton.addTarget(self, action: #selector(changePhotoTapped), for: .touchUpInside)

        let deleteButton = UIButton(type: .system)
        var deleteConfig = UIButton.Configuration.plain()
        deleteConfig.title = "Delete Milestone"
        deleteConfig.image = UIImage(systemName: "trash")
        deleteConfig.imagePadding = 8
        deleteConfig.baseForegroundColor = UIColor(hex: 0xC24E4E)
        deleteConfig.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        deleteButton.configuration = deleteConfig
        deleteButton.titleLabel?.font = Theme.Font.heading(15, weight: 700)
        deleteButton.backgroundColor = .white
        deleteButton.layer.cornerRadius = 18
        deleteButton.layer.borderWidth = 1.5
        deleteButton.layer.borderColor = UIColor(hex: 0xF0D4D4).cgColor
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        let content = UIStackView(arrangedSubviews: [photoContainer, infoCard, changePhotoButton, deleteButton])
        content.axis = .vertical
        content.spacing = 16
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

            photoContainer.heightAnchor.constraint(equalTo: photoContainer.widthAnchor, multiplier: 1.0),
            photoImageView.topAnchor.constraint(equalTo: photoContainer.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: photoContainer.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: photoContainer.trailingAnchor),
            photoImageView.bottomAnchor.constraint(equalTo: photoContainer.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: photoContainer.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: photoContainer.centerYAnchor),
            changePhoto.centerXAnchor.constraint(equalTo: photoContainer.centerXAnchor),
            changePhoto.bottomAnchor.constraint(equalTo: photoContainer.bottomAnchor, constant: -14),
            changePhoto.heightAnchor.constraint(equalToConstant: 26)
        ])
    }

    private func infoRow(label: String, value: String) -> UIView {
        let labelView = UILabel()
        labelView.text = label
        labelView.font = Theme.Font.body(12.5, weight: 600)
        labelView.textColor = Theme.Color.textSecondary

        let valueView = UILabel()
        valueView.text = value
        valueView.font = Theme.Font.heading(15.5, weight: 700)
        valueView.textColor = Theme.Color.textPrimaryAlt

        let stack = UIStackView(arrangedSubviews: [labelView, valueView])
        stack.axis = .vertical
        stack.spacing = 2
        return stack
    }

    private func loadPhoto() {
        if let photo = milestone.photo {
            photoImageView.image = photo
            return
        }
        guard let urlString = milestone.photoUrl, let url = URL(string: urlString) else { return }
        spinner.startAnimating()
        RemoteImageLoader.load(url) { [weak self] image in
            self?.spinner.stopAnimating()
            self?.photoImageView.image = image
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func changePhotoTapped() {
        HapticFeedback.light()
        let alert = UIAlertController(title: "Change Photo", message: nil, preferredStyle: .actionSheet)
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

    @objc private func deleteTapped() {
        HapticFeedback.light()
        let alert = UIAlertController(
            title: "Delete This Milestone?",
            message: "\u{201c}\(milestone.title)\u{201d} and its photo will be removed. This can't be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            MilestoneStore.shared.deleteCapture(milestoneId: self.milestone.id, fromListId: self.listId)
            HapticFeedback.success()
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

extension MilestoneDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        FaceCheck.run(on: image, presentingFrom: self) { [weak self] in
            guard let self else { return }
            self.photoImageView.image = image
            MilestoneStore.shared.updatePhoto(image, forMilestoneId: self.milestone.id, inListId: self.listId)
            HapticFeedback.success()
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
