import UIKit

/// Shows generation progress while the real Wiro submit/poll round-trip runs server-side
/// (`generateContent` Cloud Function). The progress bar is a local animation capped below 100%
/// until the network call actually resolves — showing 100% before the result exists would be
/// a fake "done" state, so it never runs ahead of the real work.
final class GenerationLoadingViewController: UIViewController {
    private let theme: ThemeCard
    private let sourceImage: UIImage
    private let percentLabel = UILabel()
    private let statusLabel = UILabel()
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private var progressFillWidth: NSLayoutConstraint!
    private var progress: CGFloat = 0
    private var timer: Timer?
    private var didFinish = false

    private static let progressCap: CGFloat = 0.92

    init(theme: ThemeCard, sourceImage: UIImage) {
        self.theme = theme
        self.sourceImage = sourceImage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setUpBackground()
        setUpContent()
        startSimulatedProgress()
        startGeneration()
    }

    private func setUpBackground() {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(hex: 0xEDE3F7).cgColor, UIColor(hex: 0xFBE1E7).cgColor, UIColor(hex: 0xFFF1E8).cgColor]
        gradient.locations = [0, 0.55, 1]
        gradient.startPoint = CGPoint(x: 0.3, y: 0)
        gradient.endPoint = CGPoint(x: 0.7, y: 1)
        gradient.frame = UIScreen.main.bounds
        view.layer.insertSublayer(gradient, at: 0)
    }

    private func setUpContent() {
        let circle = UIView()
        circle.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        circle.layer.cornerRadius = 110
        let sparkle = UIImageView(image: UIImage(systemName: "sparkles"))
        sparkle.tintColor = Theme.Color.accentEnd
        sparkle.contentMode = .scaleAspectFit
        sparkle.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(sparkle)
        circle.translatesAutoresizingMaskIntoConstraints = false

        percentLabel.font = Theme.Font.heading(40, weight: 700)
        percentLabel.textColor = Theme.Color.textPrimaryAlt
        percentLabel.textAlignment = .center
        percentLabel.text = "0%"

        progressTrack.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        progressTrack.layer.cornerRadius = 5
        progressTrack.translatesAutoresizingMaskIntoConstraints = false

        progressFill.backgroundColor = Theme.Color.accentEnd
        progressFill.layer.cornerRadius = 5
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.addSubview(progressFill)

        statusLabel.font = Theme.Font.heading(17, weight: 600)
        statusLabel.textColor = Theme.Color.purpleAccent
        statusLabel.textAlignment = .center
        statusLabel.text = "Warming up the studio…"

        let themeLabel = UILabel()
        themeLabel.font = Theme.Font.body(13, weight: 600)
        themeLabel.textColor = Theme.Color.textSecondary
        themeLabel.textAlignment = .center
        themeLabel.text = "Crafting the \u{201c}\(theme.name)\u{201d} theme"

        let stack = UIStackView(arrangedSubviews: [circle, percentLabel, progressTrack, statusLabel, themeLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.setCustomSpacing(44, after: circle)
        stack.setCustomSpacing(20, after: progressTrack)
        stack.setCustomSpacing(6, after: statusLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        progressFillWidth = progressFill.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: 220),
            circle.heightAnchor.constraint(equalToConstant: 220),
            sparkle.widthAnchor.constraint(equalToConstant: 80),
            sparkle.heightAnchor.constraint(equalToConstant: 80),
            sparkle.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            sparkle.centerYAnchor.constraint(equalTo: circle.centerYAnchor),

            progressTrack.widthAnchor.constraint(equalToConstant: 250),
            progressTrack.heightAnchor.constraint(equalToConstant: 10),
            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressFillWidth,

            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20)
        ])
    }

    private func startSimulatedProgress() {
        let messages = ["Warming up the studio…", "Adding studio lighting…", "Blending the theme…", "Finishing touches…"]
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] t in
            guard let self else { return }
            self.progress = min(Self.progressCap, self.progress + CGFloat.random(in: 0.05...0.1))
            self.updateProgressUI(messages: messages)
            if self.progress >= Self.progressCap {
                t.invalidate()
            }
        }
    }

    private func updateProgressUI(messages: [String]) {
        percentLabel.text = "\(Int(progress * 100))%"
        progressFillWidth.constant = 250 * progress
        let messageIndex = min(messages.count - 1, Int(progress * CGFloat(messages.count)))
        statusLabel.text = messages[messageIndex]
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
    }

    private func startGeneration() {
        GenerationService.generate(styleId: theme.id, sourceImage: sourceImage) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleGenerationResult(result)
            }
        }
    }

    private func handleGenerationResult(_ result: Result<GenerationResult, Error>) {
        guard !didFinish else { return }
        didFinish = true
        timer?.invalidate()

        switch result {
        case .success(let generation):
            progress = 1
            updateProgressUI(messages: ["Done!"])
            HapticFeedback.success()
            let resultVC = ResultViewController(theme: theme, sourceImage: sourceImage, resultUrl: generation.resultUrl)
            navigationController?.pushViewController(resultVC, animated: true)
        case .failure(let error):
            HapticFeedback.error()
            presentGenerationError(error)
        }
    }

    private func presentGenerationError(_ error: Error) {
        let alert = UIAlertController(
            title: "Couldn't create your portrait",
            message: "Something went wrong and your credits were refunded. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
        print("generateContent failed: \(error)")
    }

    deinit {
        timer?.invalidate()
    }
}
