import UIKit

final class GalleryDetailViewController: UIViewController {
    private let generation: Generation
    private let imageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private var loadedImage: UIImage?

    init(generation: Generation) {
        self.generation = generation
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: 0x2E2530)

        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        spinner.color = .white
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = .white
        close.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        close.layer.cornerRadius = 19
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false

        let share = UIButton(type: .system)
        share.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        share.tintColor = .white
        share.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        share.layer.cornerRadius = 19
        share.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        share.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(close)
        view.addSubview(share)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            close.widthAnchor.constraint(equalToConstant: 38),
            close.heightAnchor.constraint(equalToConstant: 38),

            share.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            share.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            share.widthAnchor.constraint(equalToConstant: 38),
            share.heightAnchor.constraint(equalToConstant: 38)
        ])

        RemoteImageLoader.load(generation.resultUrl) { [weak self] image in
            self?.spinner.stopAnimating()
            self?.loadedImage = image
            self?.imageView.image = image
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func shareTapped() {
        guard let loadedImage else { return }
        HapticFeedback.light()
        present(UIActivityViewController(activityItems: [loadedImage], applicationActivities: nil), animated: true)
    }
}
