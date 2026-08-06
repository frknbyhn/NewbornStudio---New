import UIKit

/// Lists every collage video the user has generated (see MilestoneCollageStore), newest first.
/// Reachable from the floating button at the bottom of MilestoneListsViewController. Tapping a
/// row pushes MilestoneCollageViewController for playback/save/share — same screen a freshly
/// rendered collage lands on, just fed a remote Storage URL instead of a local file this time.
final class MilestoneCollageGalleryViewController: UIViewController {
    private var stack: UIStackView!
    private var collages: [MilestoneCollageStore.SavedCollage] = []
    private let spinner = UIActivityIndicatorView(style: .large)

    private var hasLoadedOnce = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpNavBar()
        setUpList()
        loadCollages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Skips the redundant re-fetch right after viewDidLoad's own load, but picks up a
        // deletion made on MilestoneCollageViewController when popping back here.
        if hasLoadedOnce {
            loadCollages()
        }
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
        title.text = "My Collages"
        title.font = Theme.Font.heading(19, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.numberOfLines = 1

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

    private func setUpList() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 14, left: 24, bottom: 30, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: navBarBottom, constant: 6),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40)
        ])
    }

    private func loadCollages() {
        spinner.startAnimating()
        MilestoneCollageStore.fetchCollages { [weak self] result in
            guard let self else { return }
            self.spinner.stopAnimating()
            self.hasLoadedOnce = true
            switch result {
            case .success(let collages):
                self.collages = collages
                self.reload()
            case .failure:
                self.reload() // shows the empty state — a quiet failure beats a blocking error here
            }
        }
    }

    private func reload() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if collages.isEmpty {
            stack.addArrangedSubview(emptyState())
            return
        }
        for collage in collages {
            stack.addArrangedSubview(collageRow(for: collage))
        }
    }

    private func emptyState() -> UIView {
        let label = UILabel()
        label.text = "No collages yet — capture at least 5 milestones in a list, then tap \u{201c}Create Collage\u{201d} to create one."
        label.font = Theme.Font.body(14, weight: 600)
        label.textColor = Theme.Color.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func collageRow(for collage: MilestoneCollageStore.SavedCollage) -> UIView {
        let bg = UIView()
        bg.backgroundColor = Theme.Color.purpleBackground
        bg.layer.cornerRadius = 12
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.widthAnchor.constraint(equalToConstant: 44).isActive = true
        bg.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let icon = UIImageView(image: UIImage(systemName: "film.fill"))
        icon.tintColor = Theme.Color.purpleAccent
        icon.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: bg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: bg.centerYAnchor)
        ])

        let title = UILabel()
        title.text = collage.listName
        title.font = Theme.Font.heading(15.5, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt

        let subtitle = UILabel()
        subtitle.text = Self.dateFormatter.string(from: collage.createdAt)
        subtitle.font = Theme.Font.body(12.5, weight: 600)
        subtitle.textColor = Theme.Color.textSecondary

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 1
        textStack.isUserInteractionEnabled = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(hex: 0xCBBDB8)
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let spacer = UIView()
        spacer.isUserInteractionEnabled = false

        let row = PassThroughStackView(arrangedSubviews: [bg, textStack, spacer, chevron])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        row.translatesAutoresizingMaskIntoConstraints = false

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.translatesAutoresizingMaskIntoConstraints = false

        let control = MilestoneCollageControl(collage: collage)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(collageTapped(_:)), for: .touchUpInside)

        card.addSubview(control)
        card.addSubview(row)
        NSLayoutConstraint.activate([
            control.topAnchor.constraint(equalTo: card.topAnchor),
            control.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            control.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            control.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            row.topAnchor.constraint(equalTo: card.topAnchor),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    @objc private func collageTapped(_ sender: MilestoneCollageControl) {
        HapticFeedback.selection()
        navigationController?.pushViewController(
            MilestoneCollageViewController(videoURL: sender.collage.videoUrl, listName: sender.collage.listName, collageId: sender.collage.id),
            animated: true
        )
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

/// Carries the tapped collage through the UIControl target/action — mirrors
/// MilestoneListControl/MilestoneCaptureControl elsewhere in this feature.
private final class MilestoneCollageControl: UIControl {
    let collage: MilestoneCollageStore.SavedCollage
    init(collage: MilestoneCollageStore.SavedCollage) {
        self.collage = collage
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
