import UIKit

/// A single milestone list's contents. The standard list is read-only (no add/remove); custom
/// lists let the user add and remove milestones freely. Marking a milestone done/attaching a
/// photo is a later pass — this screen is just the list itself for now.
final class MilestoneListDetailViewController: UIViewController {
    private let store = MilestoneStore.shared
    private let listId: String
    private var stack: UIStackView!

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
        stack.layoutMargins = UIEdgeInsets(top: 14, left: 24, bottom: 30, right: 24)
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

    /// One continuous dashed line behind a run of rows, from the first badge's center to the
    /// last's — a per-row dashed segment (bounded by that row's own frame) left a gap at every
    /// row boundary since the stack's inter-row spacing sits outside any single row's bounds.
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

    /// Matches the Milestone Tracker mockup (Design/Newborn Studio.dc.html, section 7): a dashed
    /// timeline running behind circular badges (photo-textured pink + green check when done,
    /// dashed cream "+" when pending), each connected to a white card with the milestone's title
    /// and a colored icon tile. The mockup's card date field assumed a real captured date/photo,
    /// which we don't track yet — using an honest static status label instead of fabricating one.
    /// The dashed line itself is drawn once per run of rows by `timelineSection`, not here — the
    /// badge view is returned so the caller can anchor that line to it.
    private func milestoneRow(for milestone: Milestone, deletable: Bool) -> (row: UIView, badge: UIView) {
        let isDone = milestone.state == .done

        let badgeColumn = UIView()
        badgeColumn.translatesAutoresizingMaskIntoConstraints = false
        badgeColumn.widthAnchor.constraint(equalToConstant: 56).isActive = true

        let badge = UIView()
        badge.backgroundColor = isDone ? UIColor(hex: 0xF6DCE2) : UIColor(hex: 0xFBF4EF)
        badge.layer.cornerRadius = 27
        if !isDone {
            badge.layer.borderWidth = 2
            badge.layer.borderColor = UIColor(hex: 0xE5D2C7).cgColor
        }
        badge.translatesAutoresizingMaskIntoConstraints = false
        badgeColumn.addSubview(badge)

        let badgeIcon = UIImageView(image: UIImage(systemName: isDone ? "checkmark" : "plus"))
        badgeIcon.tintColor = isDone ? Theme.Color.success : UIColor(hex: 0xD8C4B9)
        badgeIcon.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(badgeIcon)

        NSLayoutConstraint.activate([
            badge.centerXAnchor.constraint(equalTo: badgeColumn.centerXAnchor),
            badge.topAnchor.constraint(equalTo: badgeColumn.topAnchor, constant: 4),
            badge.widthAnchor.constraint(equalToConstant: 54),
            badge.heightAnchor.constraint(equalToConstant: 54),
            badgeIcon.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            badgeIcon.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
        ])

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

        let iconTile = UIView()
        iconTile.backgroundColor = milestone.style.tint
        iconTile.layer.cornerRadius = 12
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

        var cardArranged: [UIView] = [textStack, UIView(), iconTile]
        if deletable {
            let delete = UIButton(type: .system)
            delete.setImage(UIImage(systemName: "trash"), for: .normal)
            delete.tintColor = UIColor(hex: 0xD8A6A6)
            delete.addAction(UIAction { [weak self] _ in self?.removeMilestone(milestone.id) }, for: .touchUpInside)
            cardArranged.append(delete)
        }

        let cardContent = UIStackView(arrangedSubviews: cardArranged)
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
        row.alignment = .top
        return (row, badge)
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

    private func removeMilestone(_ id: String) {
        HapticFeedback.light()
        store.removeMilestone(id: id, fromListId: listId)
        reload()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
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
