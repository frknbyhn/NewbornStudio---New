import UIKit

final class ResultViewController: UIViewController {
    private let theme: ThemeCard
    private let sourceImage: UIImage

    init(theme: ThemeCard, sourceImage: UIImage) {
        self.theme = theme
        self.sourceImage = sourceImage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        view.backgroundColor = UIColor(hex: 0x2E2530)
        setUpTopBar()
        setUpImage()
        setUpActions()
    }

    private func setUpTopBar() {
        let back = circleButton(icon: "arrow.left")
        back.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        let more = circleButton(icon: "ellipsis")

        let title = UILabel()
        title.text = "Your portrait"
        title.font = Theme.Font.heading(16, weight: 700)
        title.textColor = .white

        let bar = UIStackView(arrangedSubviews: [back, title, more])
        bar.axis = .horizontal
        bar.distribution = .equalSpacing
        bar.alignment = .center
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)

        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22)
        ])
        topBarBottom = bar.bottomAnchor
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

        let imageView = UIImageView(image: sourceImage)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)

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

            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            watermark.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
            watermark.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        imageContainer = container
    }

    private var imageContainer: UIView!

    private func setUpActions() {
        let actions = UIStackView(arrangedSubviews: [
            actionButton(icon: "square.and.arrow.down", title: "Save", action: #selector(saveTapped)),
            actionButton(icon: "square.and.arrow.up", title: "Share", action: #selector(shareTapped)),
            actionButton(icon: "arrow.clockwise", title: "Retry", action: #selector(retryTapped))
        ])
        actions.axis = .horizontal
        actions.distribution = .equalSpacing
        actions.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actions)

        NSLayoutConstraint.activate([
            actions.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 22),
            actions.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            actions.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
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
        return stack
    }

    @objc private func backTapped() { navigationController?.popToRootViewController(animated: true) }
    @objc private func saveTapped() {
        HapticFeedback.success()
        UIImageWriteToSavedPhotosAlbum(sourceImage, nil, nil, nil)
    }
    @objc private func shareTapped() {
        HapticFeedback.light()
        present(UIActivityViewController(activityItems: [sourceImage], applicationActivities: nil), animated: true)
    }
    @objc private func retryTapped() {
        HapticFeedback.light()
        navigationController?.popViewController(animated: true)
    }
}
