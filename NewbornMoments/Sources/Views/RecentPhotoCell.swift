import UIKit

/// One thumbnail in a "Recently Used" photo strip (Photo Upload, Milestone Capture, ...). A
/// plain UIControl (not a gesture recognizer on top of a UIView) so the delete button — a
/// subview positioned over its top-trailing corner — naturally wins its own touches via normal
/// view-hierarchy hit-testing, without fighting a parent gesture recognizer for them.
final class RecentPhotoCell: UIControl {
    var onSelect: (() -> Void)?
    var onDelete: (() -> Void)?

    private let imageView = UIImageView()
    private let checkBadge = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))

    init(photo: RecentPhotosStore.Photo, isSelected: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 64).isActive = true
        heightAnchor.constraint(equalToConstant: 64).isActive = true

        imageView.image = photo.image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 14
        imageView.layer.borderWidth = isSelected ? 3 : 0
        imageView.layer.borderColor = Theme.Color.success.cgColor
        imageView.isUserInteractionEnabled = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        checkBadge.tintColor = Theme.Color.success
        checkBadge.backgroundColor = .white
        checkBadge.layer.cornerRadius = 8
        checkBadge.isHidden = !isSelected
        checkBadge.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkBadge)

        let deleteButton = UIButton(type: .system)
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = Theme.Color.textSecondary
        deleteButton.backgroundColor = .white
        deleteButton.layer.cornerRadius = 9
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(deleteButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            checkBadge.widthAnchor.constraint(equalToConstant: 16),
            checkBadge.heightAnchor.constraint(equalToConstant: 16),
            checkBadge.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 2),
            checkBadge.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 2),

            deleteButton.widthAnchor.constraint(equalToConstant: 18),
            deleteButton.heightAnchor.constraint(equalToConstant: 18),
            deleteButton.topAnchor.constraint(equalTo: topAnchor, constant: -6),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 6)
        ])

        addTarget(self, action: #selector(selfTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func selfTapped() { onSelect?() }
    @objc private func deleteTapped() { onDelete?() }
}
