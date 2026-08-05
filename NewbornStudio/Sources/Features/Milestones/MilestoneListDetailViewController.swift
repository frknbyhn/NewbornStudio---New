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
                let card = UIStackView(arrangedSubviews: milestones.map { milestoneRow(for: $0, deletable: false) })
                card.axis = .vertical
                card.spacing = 0
                card.backgroundColor = .white
                card.layer.cornerRadius = 18
                card.layer.masksToBounds = true
                addDividers(to: card)
                stack.addArrangedSubview(card)
            }
        } else {
            if current.milestones.isEmpty {
                stack.addArrangedSubview(emptyState())
            } else {
                let card = UIStackView(arrangedSubviews: current.milestones.map { milestoneRow(for: $0, deletable: true) })
                card.axis = .vertical
                card.spacing = 0
                card.backgroundColor = .white
                card.layer.cornerRadius = 18
                card.layer.masksToBounds = true
                addDividers(to: card)
                stack.addArrangedSubview(card)
            }
            stack.addArrangedSubview(addMilestoneButton())
        }
    }

    private func addDividers(to card: UIStackView) {
        for (index, row) in card.arrangedSubviews.enumerated() where index < card.arrangedSubviews.count - 1 {
            let divider = UIView()
            divider.backgroundColor = UIColor(hex: 0xF2EAE4)
            divider.translatesAutoresizingMaskIntoConstraints = false
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            row.addSubview(divider)
            NSLayoutConstraint.activate([
                divider.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
                divider.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                divider.bottomAnchor.constraint(equalTo: row.bottomAnchor)
            ])
        }
    }

    private func sectionHeader(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = Theme.Font.heading(13.5, weight: 700)
        label.textColor = Theme.Color.textSecondary
        return label
    }

    private func milestoneRow(for milestone: Milestone, deletable: Bool) -> UIView {
        let isDone = milestone.state == .done
        let circle = UIView()
        circle.backgroundColor = isDone ? UIColor(hex: 0xF6DCE2) : UIColor(hex: 0xFBF4EF)
        circle.layer.cornerRadius = 20
        if !isDone {
            circle.layer.borderWidth = 2
            circle.layer.borderColor = UIColor(hex: 0xE5D2C7).cgColor
        }
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.widthAnchor.constraint(equalToConstant: 40).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let icon = UIImageView(image: UIImage(systemName: isDone ? "checkmark" : "circle"))
        icon.tintColor = isDone ? Theme.Color.success : UIColor(hex: 0xD8C4B9)
        icon.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: circle.centerYAnchor)
        ])

        let label = UILabel()
        label.text = milestone.title
        label.font = Theme.Font.heading(15, weight: 600)
        label.textColor = isDone ? Theme.Color.textPrimaryAlt : Theme.Color.textSecondary

        var arranged: [UIView] = [circle, label, UIView()]
        if deletable {
            let delete = UIButton(type: .system)
            delete.setImage(UIImage(systemName: "trash"), for: .normal)
            delete.tintColor = UIColor(hex: 0xD8A6A6)
            delete.addAction(UIAction { [weak self] _ in self?.removeMilestone(milestone.id) }, for: .touchUpInside)
            arranged.append(delete)
        }

        let row = UIStackView(arrangedSubviews: arranged)
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return row
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
