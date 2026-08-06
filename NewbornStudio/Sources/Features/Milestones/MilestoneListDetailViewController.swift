import UIKit

/// A single milestone list's contents. The standard list is read-only (no add/remove); custom
/// lists let the user add and remove milestones freely. Tapping a pending milestone opens
/// MilestoneCaptureViewController to capture it with a photo (optionally AI touched-up).
final class MilestoneListDetailViewController: UIViewController {
    private let store = MilestoneStore.shared
    private let listId: String
    private var stack: UIStackView!
    private let collageButton = GradientPillButton(title: "Kolaj Oluştur", icon: UIImage(systemName: "square.grid.2x2.fill"))

    init(list: MilestoneList) {
        self.listId = list.id
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var list: MilestoneList {
        store.lists.first { $0.id == listId } ?? MilestoneList(id: listId, name: "", isStandard: true, milestones: [])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpNavBar()
        setUpList()
        setUpCollageButton()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Picks up a capture made on MilestoneCaptureViewController since this screen last
        // appeared (state/photo/counts all live in the shared store, not local state here).
        reload()
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
        title.text = list.name
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
        stack.spacing = 18
        stack.isLayoutMarginsRelativeArrangement = true
        // Extra bottom margin (vs. a plain 30) so the last row can scroll clear of the floating
        // "Kolaj Oluştur" button pinned over the content — see setUpCollageButton().
        stack.layoutMargins = UIEdgeInsets(top: 14, left: 24, bottom: 100, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: navBarBottom, constant: 6),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])
    }

    /// Floating over the scrollable list (not part of its content) so it's always reachable —
    /// action wired up in a later pass, this is just the button itself for now.
    private func setUpCollageButton() {
        let fade = UIView()
        fade.translatesAutoresizingMaskIntoConstraints = false
        fade.isUserInteractionEnabled = false
        view.addSubview(fade)

        let gradient = CAGradientLayer()
        gradient.colors = [Theme.Color.backgroundCream.withAlphaComponent(0).cgColor, Theme.Color.backgroundCream.cgColor]
        gradient.locations = [0, 0.4]
        fade.layer.addSublayer(gradient)

        collageButton.addTarget(self, action: #selector(collageTapped), for: .touchUpInside)
        collageButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collageButton)

        NSLayoutConstraint.activate([
            fade.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fade.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fade.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            fade.topAnchor.constraint(equalTo: collageButton.topAnchor, constant: -28),

            collageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            collageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            collageButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        collageButtonFadeLayer = gradient
        collageButtonFadeView = fade
    }

    private var collageButtonFadeLayer: CAGradientLayer!
    private var collageButtonFadeView: UIView!

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collageButtonFadeLayer?.frame = collageButtonFadeView?.bounds ?? .zero
    }

    private static let minCaptureCountForCollage = 5

    @objc private func collageTapped() {
        HapticFeedback.light()
        // Item order, not capture-date order — the video is meant to read like the list itself
        // (chronological for standard lists, insertion order for custom ones), not shuffled by
        // whenever each one happened to get captured.
        let captured = list.milestones.filter { $0.state == .done }
        guard captured.count >= Self.minCaptureCountForCollage else {
            let alert = UIAlertController(
                title: "Not Enough Milestones Yet",
                message: "You need at least \(Self.minCaptureCountForCollage) captured milestones to create a collage video. You have \(captured.count) so far.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        startCollageGeneration(for: captured)
    }

    // MARK: - Collage generation

    private var collageProgressOverlay: UIView?
    private var collageProgressLabel: UILabel?

    private func startCollageGeneration(for captured: [Milestone]) {
        showCollageProgressOverlay()
        resolveImages(for: captured) { [weak self] items in
            guard let self else { return }
            guard !items.isEmpty else {
                self.hideCollageProgressOverlay()
                self.presentCollageErrorAlert()
                return
            }
            MilestoneVideoRenderer.renderCollage(listName: self.list.name, items: items, progress: { [weak self] fraction in
                self?.collageProgressLabel?.text = "Creating your collage… \(Int(fraction * 100))%"
            }, completion: { [weak self] result in
                guard let self else { return }
                self.hideCollageProgressOverlay()
                switch result {
                case .success(let url):
                    HapticFeedback.success()
                    // Pushes the local file immediately (instant, no network wait) while the
                    // upload to "Kolajlarım" happens in the background — see MilestoneCollageStore.
                    let collageId = MilestoneCollageStore.saveCollage(localFileURL: url, listId: self.listId, listName: self.list.name)
                    self.navigationController?.pushViewController(MilestoneCollageViewController(videoURL: url, listName: self.list.name, collageId: collageId), animated: true)
                case .failure:
                    self.presentCollageErrorAlert()
                }
            })
        }
    }

    /// A captured milestone's photo is already in memory only if this session captured it —
    /// after a relaunch, only `photoUrl` survives (see MilestoneStore/MilestoneRemoteStore), so
    /// this resolves whichever source each one actually has before rendering can start.
    private func resolveImages(for captured: [Milestone], completion: @escaping ([MilestoneVideoRenderer.Item]) -> Void) {
        var items: [MilestoneVideoRenderer.Item?] = Array(repeating: nil, count: captured.count)
        let group = DispatchGroup()
        for (index, milestone) in captured.enumerated() {
            if let photo = milestone.photo {
                items[index] = MilestoneVideoRenderer.Item(title: milestone.title, image: photo, capturedAt: milestone.capturedAt)
                continue
            }
            guard let urlString = milestone.photoUrl, let url = URL(string: urlString) else { continue }
            group.enter()
            RemoteImageLoader.load(url) { image in
                if let image {
                    items[index] = MilestoneVideoRenderer.Item(title: milestone.title, image: image, capturedAt: milestone.capturedAt)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(items.compactMap { $0 })
        }
    }

    private func showCollageProgressOverlay() {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        overlay.translatesAutoresizingMaskIntoConstraints = false

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Creating your collage… 0%"
        label.font = Theme.Font.heading(15, weight: 700)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [spinner, label])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(stack)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: overlay.trailingAnchor, constant: -40)
        ])

        collageProgressOverlay = overlay
        collageProgressLabel = label
    }

    private func hideCollageProgressOverlay() {
        collageProgressOverlay?.removeFromSuperview()
        collageProgressOverlay = nil
        collageProgressLabel = nil
    }

    private func presentCollageErrorAlert() {
        let alert = UIAlertController(
            title: "Something Went Wrong",
            message: "We couldn't create the collage video. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func reload() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let current = list

        if current.isStandard {
            let groups = current.milestones.reduce(into: [(String, [Milestone])]()) { acc, milestone in
                let group = milestone.group ?? ""
                if let lastIndex = acc.indices.last, acc[lastIndex].0 == group {
                    acc[lastIndex].1.append(milestone)
                } else {
                    acc.append((group, [milestone]))
                }
            }
            for (group, milestones) in groups {
                if !group.isEmpty {
                    stack.addArrangedSubview(sectionHeader(group))
                }
                stack.addArrangedSubview(timelineSection(milestones, deletable: false))
            }
        } else {
            if current.milestones.isEmpty {
                stack.addArrangedSubview(emptyState())
            } else {
                stack.addArrangedSubview(timelineSection(current.milestones, deletable: true))
            }
            stack.addArrangedSubview(addMilestoneButton())
        }
    }

    private func timelineSection(_ milestones: [Milestone], deletable: Bool) -> UIView {
        var rows: [UIView] = []
        var badges: [UIView] = []
        for milestone in milestones {
            let (row, badge) = milestoneRow(for: milestone, deletable: deletable)
            rows.append(row)
            badges.append(badge)
        }

        let rowsStack = UIStackView(arrangedSubviews: rows)
        rowsStack.axis = .vertical
        rowsStack.spacing = 14
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // rowsStack (which the badges live inside) must already be in the hierarchy before any
        // constraint referencing a badge can be activated — otherwise the badge and dashedLine
        // share no common ancestor yet and activation crashes.
        container.addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: container.topAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        if let first = badges.first, let last = badges.last, badges.count > 1 {
            let dashedLine = DashedLineView()
            dashedLine.translatesAutoresizingMaskIntoConstraints = false
            // Inserted behind rowsStack so the (opaque) badges and cards draw on top of it.
            container.insertSubview(dashedLine, at: 0)
            NSLayoutConstraint.activate([
                dashedLine.centerXAnchor.constraint(equalTo: first.centerXAnchor),
                dashedLine.widthAnchor.constraint(equalToConstant: 2),
                dashedLine.topAnchor.constraint(equalTo: first.centerYAnchor),
                dashedLine.bottomAnchor.constraint(equalTo: last.centerYAnchor)
            ])
        }
        return container
    }

    private func sectionHeader(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = Theme.Font.heading(13.5, weight: 700)
        label.textColor = Theme.Color.textSecondary
        return label
    }

    private func milestoneRow(for milestone: Milestone, deletable: Bool) -> (row: UIView, badge: UIView) {
        let isDone = milestone.state == .done

        let badgeColumn = UIView()
        badgeColumn.translatesAutoresizingMaskIntoConstraints = false
        badgeColumn.widthAnchor.constraint(equalToConstant: 56).isActive = true

        let badge = UIView()
        badge.backgroundColor = isDone ? Theme.Color.success : UIColor(hex: 0xFBF4EF)
        badge.layer.cornerRadius = 27
        badge.layer.masksToBounds = true
        if !isDone {
            badge.layer.borderWidth = 2
            badge.layer.borderColor = UIColor(hex: 0xE5D2C7).cgColor
        }
        badge.translatesAutoresizingMaskIntoConstraints = false
        badgeColumn.addSubview(badge)

        let badgeIcon = UIImageView(image: UIImage(systemName: isDone ? "checkmark" : "plus"))
        badgeIcon.tintColor = isDone ? .white : UIColor(hex: 0xD8C4B9)
        badgeIcon.contentMode = .scaleAspectFit
        badgeIcon.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(badgeIcon)
        NSLayoutConstraint.activate([
            badgeIcon.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            badgeIcon.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            badgeIcon.widthAnchor.constraint(equalToConstant: isDone ? 24 : 18),
            badgeIcon.heightAnchor.constraint(equalToConstant: isDone ? 24 : 18)
        ])

        NSLayoutConstraint.activate([
            badge.centerXAnchor.constraint(equalTo: badgeColumn.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: badgeColumn.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 54),
            badge.heightAnchor.constraint(equalToConstant: 54)
        ])

        // The "+" badge itself reads as a tappable add button — people tap it directly instead
        // of (or as well as) the card, so it needs its own capture control, not just the card's.
        if !isDone {
            let badgeCaptureControl = MilestoneCaptureControl(milestone: milestone)
            badgeCaptureControl.translatesAutoresizingMaskIntoConstraints = false
            badgeCaptureControl.addTarget(self, action: #selector(captureTapped(_:)), for: .touchUpInside)
            badgeColumn.addSubview(badgeCaptureControl)
            NSLayoutConstraint.activate([
                badgeCaptureControl.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
                badgeCaptureControl.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
                badgeCaptureControl.widthAnchor.constraint(equalToConstant: 54),
                badgeCaptureControl.heightAnchor.constraint(equalToConstant: 54)
            ])
        }

        let title = UILabel()
        title.text = milestone.title
        title.font = Theme.Font.heading(16, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt
        title.numberOfLines = 2

        let status = UILabel()
        status.text = isDone ? "Captured" : "Not yet captured"
        status.font = Theme.Font.body(12, weight: 600)
        status.textColor = Theme.Color.textSecondary

        let textStack = UIStackView(arrangedSubviews: [title, status])
        textStack.axis = .vertical
        textStack.spacing = 2
        // Every plain (non-actionable) view stacked into cardContent needs this — see the
        // spacer below for the full explanation. Labels default to disabled already, but the
        // UIStackView wrapping them does NOT, and it's the stack (not the labels) that
        // hit-tests as covering this whole area.
        textStack.isUserInteractionEnabled = false

        let iconTile = UIView()
        iconTile.backgroundColor = milestone.style.tint
        iconTile.layer.cornerRadius = 12
        // Decorative only — without this, a tap landing exactly on the tile is swallowed here
        // (its default is enabled) instead of passing through to the capture control behind it.
        iconTile.isUserInteractionEnabled = false
        iconTile.translatesAutoresizingMaskIntoConstraints = false
        iconTile.widthAnchor.constraint(equalToConstant: 46).isActive = true
        iconTile.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let tileIcon = UIImageView(image: UIImage(systemName: milestone.style.icon))
        tileIcon.tintColor = milestone.style.ink
        tileIcon.translatesAutoresizingMaskIntoConstraints = false
        iconTile.addSubview(tileIcon)
        NSLayoutConstraint.activate([
            tileIcon.centerXAnchor.constraint(equalTo: iconTile.centerXAnchor),
            tileIcon.centerYAnchor.constraint(equalTo: iconTile.centerYAnchor)
        ])

        // The flexible spacer that pushes iconTile to the trailing edge — by far the largest
        // area of the card, and a plain UIView defaults to isUserInteractionEnabled = true, so
        // without this line it silently wins hit-testing over the whole middle of the card
        // (a tap there hits this instead of falling through to captureControl/detailControl
        // behind cardContent). THIS was the actual bug behind "can't open milestone detail" —
        // the row's own tap control was never broken, taps just never reached it. Same root
        // cause applies to any future card built the same way (content stack on top of a
        // full-bounds tap control): every non-actionable view in that stack — including bare
        // spacers and stacks that only wrap non-interactive labels — needs this set explicitly.
        // Only genuinely actionable subviews (like the delete button below) should stay enabled.
        let spacer = UIView()
        spacer.isUserInteractionEnabled = false

        var cardArranged: [UIView] = [textStack, spacer, iconTile]
        if deletable {
            let delete = UIButton(type: .system)
            delete.setImage(UIImage(systemName: "trash"), for: .normal)
            delete.tintColor = UIColor(hex: 0xD8A6A6)
            delete.addAction(UIAction { [weak self] _ in self?.confirmRemoveIfNeeded(milestone) }, for: .touchUpInside)
            cardArranged.append(delete)
        }

        // PassThroughStackView, not a plain UIStackView — this container sits on top of
        // captureControl/detailControl below, and a plain stack's default hitTest wins over
        // that control for every point not claimed by one of its own children (a delete button
        // still resolves normally; see PassThroughStackView's doc comment for the full story —
        // this is what was actually blocking taps to the detail screen).
        let cardContent = PassThroughStackView(arrangedSubviews: cardArranged)
        cardContent.axis = .horizontal
        cardContent.spacing = 12
        cardContent.alignment = .center
        cardContent.isLayoutMarginsRelativeArrangement = true
        cardContent.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        cardContent.translatesAutoresizingMaskIntoConstraints = false

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.layer.shadowColor = Theme.Color.textPrimary.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.translatesAutoresizingMaskIntoConstraints = false

        // Added BEFORE cardContent so the delete button (a real subview inside cardContent,
        // added after/on top) still wins hit-testing on its own frame — this control only
        // catches taps elsewhere on the card. Pending milestones open the capture flow; done
        // ones open the detail/edit screen instead.
        if !isDone {
            let captureControl = MilestoneCaptureControl(milestone: milestone)
            captureControl.translatesAutoresizingMaskIntoConstraints = false
            captureControl.addTarget(self, action: #selector(captureTapped(_:)), for: .touchUpInside)
            card.addSubview(captureControl)
            NSLayoutConstraint.activate([
                captureControl.topAnchor.constraint(equalTo: card.topAnchor),
                captureControl.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                captureControl.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                captureControl.bottomAnchor.constraint(equalTo: card.bottomAnchor)
            ])
        } else {
            let detailControl = MilestoneCaptureControl(milestone: milestone)
            detailControl.translatesAutoresizingMaskIntoConstraints = false
            detailControl.addTarget(self, action: #selector(detailTapped(_:)), for: .touchUpInside)
            card.addSubview(detailControl)
            NSLayoutConstraint.activate([
                detailControl.topAnchor.constraint(equalTo: card.topAnchor),
                detailControl.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                detailControl.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                detailControl.bottomAnchor.constraint(equalTo: card.bottomAnchor)
            ])
        }

        card.addSubview(cardContent)
        NSLayoutConstraint.activate([
            cardContent.topAnchor.constraint(equalTo: card.topAnchor),
            cardContent.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            cardContent.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            cardContent.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        let row = UIStackView(arrangedSubviews: [badgeColumn, card])
        row.axis = .horizontal
        row.spacing = 16
        // .fill stretches badgeColumn to the card's full height so the badge's centerY
        // constraint actually centers it against the card, not just against its own column.
        row.alignment = .fill
        return (row, badge)
    }

    @objc private func captureTapped(_ sender: MilestoneCaptureControl) {
        HapticFeedback.selection()
        navigationController?.pushViewController(MilestoneCaptureViewController(milestone: sender.milestone, listId: listId), animated: true)
    }

    @objc private func detailTapped(_ sender: MilestoneCaptureControl) {
        HapticFeedback.selection()
        navigationController?.pushViewController(MilestoneDetailViewController(milestone: sender.milestone, listId: listId), animated: true)
    }

    private func emptyState() -> UIView {
        let label = UILabel()
        label.text = "No milestones yet — add your first one below."
        label.font = Theme.Font.body(14, weight: 600)
        label.textColor = Theme.Color.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    private func addMilestoneButton() -> UIView {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "Add Milestone"
        config.image = UIImage(systemName: "plus.circle.fill")
        config.imagePadding = 8
        config.baseForegroundColor = Theme.Color.accentEnd
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        button.configuration = config
        button.titleLabel?.font = Theme.Font.heading(15, weight: 700)
        button.backgroundColor = .white
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor(hex: 0xE5D2C7).cgColor
        button.addTarget(self, action: #selector(addMilestoneTapped), for: .touchUpInside)
        return button
    }

    @objc private func addMilestoneTapped() {
        HapticFeedback.light()
        let alert = UIAlertController(title: "New Milestone", message: "What would you like to remember?", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "e.g. Met Grandma" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            guard let self, let title = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { return }
            self.store.addMilestone(title: title, toListId: self.listId)
            self.reload()
        })
        present(alert, animated: true)
    }

    /// Deleting an already-captured custom milestone loses its photo for good, so it gets a
    /// confirmation; a not-yet-captured one is just an empty row, safe to remove directly.
    private func confirmRemoveIfNeeded(_ milestone: Milestone) {
        guard milestone.state == .done else {
            removeMilestone(milestone.id)
            return
        }
        HapticFeedback.light()
        let alert = UIAlertController(
            title: "Delete Captured Milestone?",
            message: "\u{201c}\(milestone.title)\u{201d} has already been captured. Deleting it removes the photo too — this can't be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.removeMilestone(milestone.id)
        })
        present(alert, animated: true)
    }

    private func removeMilestone(_ id: String) {
        HapticFeedback.light()
        store.removeMilestone(id: id, fromListId: listId)
        reload()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

/// Carries the tapped milestone through the UIControl target/action, which has no payload of
/// its own — mirrors MilestoneListControl in MilestoneListsViewController.swift.
private final class MilestoneCaptureControl: UIControl {
    let milestone: Milestone
    init(milestone: Milestone) {
        self.milestone = milestone
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// The dashed vertical connector threading through each row's badge column, per the mockup.
private final class DashedLineView: UIView {
    private let dashLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        dashLayer.strokeColor = UIColor(hex: 0xEAD9CF).cgColor
        dashLayer.lineWidth = 2
        dashLayer.lineDashPattern = [4, 4]
        layer.addSublayer(dashLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.midX, y: 0))
        path.addLine(to: CGPoint(x: bounds.midX, y: bounds.height))
        dashLayer.path = path.cgPath
    }
}
