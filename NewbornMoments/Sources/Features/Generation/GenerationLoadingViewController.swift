import UIKit
import Lottie

/// Shows generation progress while the real Wiro submit/poll round-trip runs server-side
/// (`generateContent` Cloud Function). The progress bar is a local animation capped below 100%
/// until the network call actually resolves — showing 100% before the result exists would be
/// a fake "done" state, so it never runs ahead of the real work. The screen enforces a hard
/// 15-second floor on success: if the real result lands sooner, the bar just waits at its
/// paced position until the floor is reached, then snaps to 100% and transitions — a real
/// result arriving in 2s shouldn't make the "studio" feel instant. Failures skip the floor
/// and surface immediately, since there's no anticipation to preserve for an error.
final class GenerationLoadingViewController: UIViewController {
    private let theme: ThemeCard
    private let sourceImage: UIImage
    private let editInstruction: String?
    /// Forwarded to GenerationService — see its doc comment. Only meaningful alongside a real
    /// editInstruction.
    private let allowPoseChange: Bool
    /// Forwarded to ResultViewController — when set, closing that screen saves the result onto
    /// this milestone and returns to its list instead of the default popToRoot.
    private let milestoneContext: MilestoneCaptureContext?
    private let percentLabel = UILabel()
    private let statusLabel = UILabel()
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private var progressFillWidth: NSLayoutConstraint!
    private var progress: CGFloat = 0
    private var timer: Timer?
    private var didFinish = false
    private var serverResult: Result<GenerationResult, Error>?
    private var startTime: Date!

    private static let progressCap: CGFloat = 0.92
    private static let tickInterval: TimeInterval = 0.3
    private static let minimumDuration: TimeInterval = 15

    init(theme: ThemeCard, sourceImage: UIImage, editInstruction: String? = nil, allowPoseChange: Bool = false, milestoneContext: MilestoneCaptureContext? = nil) {
        self.theme = theme
        self.sourceImage = sourceImage
        self.editInstruction = editInstruction
        self.allowPoseChange = allowPoseChange
        self.milestoneContext = milestoneContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        startTime = Date()
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
        circle.translatesAutoresizingMaskIntoConstraints = false

        // loader.json — bundled Lottie animation, replacing the old static sparkles icon so
        // this screen actually feels like it's doing something during the wait.
        let loader = LottieAnimationView(name: "loader")
        loader.loopMode = .loop
        loader.contentMode = .scaleAspectFit
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.play()
        circle.addSubview(loader)

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
        themeLabel.text = editInstruction != nil ? "Applying your edit" : "Crafting the \u{201c}\(theme.name)\u{201d} theme"

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
            loader.widthAnchor.constraint(equalToConstant: 140),
            loader.heightAnchor.constraint(equalToConstant: 140),
            loader.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: circle.centerYAnchor),

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

    private let messages = ["Warming up the studio…", "Adding studio lighting…", "Blending the theme…", "Finishing touches…"]

    /// Paced to reach progressCap right around the 15s floor. Keeps ticking (and re-checking
    /// the floor) even after reaching the cap, in case the server is slower than 15s.
    private func startSimulatedProgress() {
        let ticks = Self.minimumDuration / Self.tickInterval
        let perTick = Self.progressCap / CGFloat(ticks)
        timer = Timer.scheduledTimer(withTimeInterval: Self.tickInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.progress = min(Self.progressCap, self.progress + perTick * CGFloat.random(in: 0.7...1.3))
            self.updateProgressUI(messages: self.messages)
            self.finishIfFloorReached()
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
        GenerationService.generate(styleId: theme.id, sourceImage: sourceImage, editInstruction: editInstruction, allowPoseChange: allowPoseChange) { [weak self] result in
            DispatchQueue.main.async {
                guard let self, !self.didFinish else { return }
                if case .failure = result {
                    // Failures skip the 15s floor entirely — surface them immediately.
                    self.finish(with: result)
                } else {
                    self.serverResult = result
                    self.finishIfFloorReached()
                }
            }
        }
    }

    /// Completes only once BOTH the real result exists AND the 15s floor has elapsed —
    /// called on every tick and right when the network call resolves, whichever comes last.
    private func finishIfFloorReached() {
        guard let serverResult, !didFinish, Date().timeIntervalSince(startTime) >= Self.minimumDuration else { return }
        finish(with: serverResult)
    }

    private func finish(with result: Result<GenerationResult, Error>) {
        guard !didFinish else { return }
        didFinish = true
        timer?.invalidate()

        switch result {
        case .success(let generation):
            progress = 1
            UIView.animate(withDuration: 0.35) {
                self.progressFillWidth.constant = 250
                self.view.layoutIfNeeded()
            }
            percentLabel.text = "100%"
            statusLabel.text = "Done!"
            HapticFeedback.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self else { return }
                let resultVC = ResultViewController(theme: self.theme, sourceImage: self.sourceImage, resultUrl: generation.resultUrl, milestoneContext: self.milestoneContext, autoSaveEligible: true)
                self.navigationController?.pushViewController(resultVC, animated: true)
            }
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
