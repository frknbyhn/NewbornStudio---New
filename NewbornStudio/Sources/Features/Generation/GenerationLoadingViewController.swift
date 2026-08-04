import UIKit

/// Shows generation progress. Currently simulated locally — the real Wiro submit/poll
/// round-trip via a Cloud Function (`generateContent`) is wired in Phase 6.
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
            self.progress = min(1, self.progress + CGFloat.random(in: 0.08...0.16))
            self.percentLabel.text = "\(Int(self.progress * 100))%"
            self.progressFillWidth.constant = 250 * self.progress
            let messageIndex = min(messages.count - 1, Int(self.progress * CGFloat(messages.count)))
            self.statusLabel.text = messages[messageIndex]
            UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
            if self.progress >= 1 {
                t.invalidate()
                self.finish()
            }
        }
    }

    private func finish() {
        HapticFeedback.success()
        let result = ResultViewController(theme: theme, sourceImage: sourceImage)
        navigationController?.pushViewController(result, animated: true)
    }

    deinit {
        timer?.invalidate()
    }
}
