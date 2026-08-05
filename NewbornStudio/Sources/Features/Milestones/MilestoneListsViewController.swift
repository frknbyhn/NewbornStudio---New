import UIKit

/// Top of the Milestones tab — a list of milestone lists: the fixed standard list plus any
/// custom lists the user creates. Private to the user — never shared, no social layer (see
/// DECISIONS.md). Tapping a list pushes MilestoneListDetailViewController.
final class MilestoneListsViewController: UIViewController {
    private let store = MilestoneStore.shared
    private var stack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpHeader()
        setUpList()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
        if !store.hasLoadedRemote {
            store.loadFromRemote { [weak self] in self?.reload() }
        }
    }

    private var headerBottom: NSLayoutYAxisAnchor!

    private func setUpHeader() {
        let title = UILabel()
        title.text = "Your baby's milestones"
        title.font = Theme.Font.heading(23, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt

        let subtitle = UILabel()
        subtitle.text = "Keep a list for every moment worth remembering"
        subtitle.font = Theme.Font.body(13, weight: 600)
        subtitle.textColor = Theme.Color.textSecondary

        let headerStack = UIStackView(arrangedSubviews: [title, subtitle])
        headerStack.axis = .vertical
        headerStack.spacing = 2
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerStack)
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
        headerBottom = headerStack.bottomAnchor
    }

    private func setUpList() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 24, bottom: 30, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: headerBottom, constant: 14),
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

        for list in store.lists.filter({ $0.isStandard }) {
            stack.addArrangedSubview(listRow(for: list))
        }
        for list in store.lists.filter({ !$0.isStandard }) {
            stack.addArrangedSubview(listRow(for: list))
        }
        stack.addArrangedSubview(addListRow())
    }

    private func listRow(for list: MilestoneList) -> UIView {
        let done = list.milestones.filter { $0.state == .done }.count

        let bg = UIView()
        bg.backgroundColor = list.isStandard ? Theme.Color.purpleBackground : UIColor(hex: 0xFCE6EC)
        bg.layer.cornerRadius = 12
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.widthAnchor.constraint(equalToConstant: 44).isActive = true
        bg.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let icon = UIImageView(image: UIImage(systemName: list.isStandard ? "star.fill" : "list.bullet"))
        icon.tintColor = list.isStandard ? Theme.Color.purpleAccent : Theme.Color.accentEnd
        icon.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: bg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: bg.centerYAnchor)
        ])

        let title = UILabel()
        title.text = list.name
        title.font = Theme.Font.heading(15.5, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt

        let subtitle = UILabel()
        subtitle.text = "\(done) of \(list.milestones.count) captured"
        subtitle.font = Theme.Font.body(12.5, weight: 600)
        subtitle.textColor = Theme.Color.textSecondary

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 1

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(hex: 0xCBBDB8)
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [bg, textStack, UIView(), chevron])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        // UIStackView.hitTest returns nil in the gaps between arranged subviews — disabling
        // interaction on it forces every tap in the control's full bounds to hit `control`.
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.translatesAutoresizingMaskIntoConstraints = false

        let control = MilestoneListControl(list: list)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(listTapped(_:)), for: .touchUpInside)

        card.addSubview(row)
        card.addSubview(control)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            control.topAnchor.constraint(equalTo: card.topAnchor),
            control.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            control.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            control.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    private func addListRow() -> UIView {
        let bg = UIView()
        bg.backgroundColor = Theme.Color.backgroundWarm
        bg.layer.cornerRadius = 12
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.widthAnchor.constraint(equalToConstant: 44).isActive = true
        bg.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let icon = UIImageView(image: UIImage(systemName: "plus"))
        icon.tintColor = Theme.Color.textSecondaryAlt
        icon.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: bg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: bg.centerYAnchor)
        ])

        let title = UILabel()
        title.text = "Add List"
        title.font = Theme.Font.heading(15.5, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt

        let row = UIStackView(arrangedSubviews: [bg, title, UIView()])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false

        let card = UIView()
        card.backgroundColor = .white
        card.layer.borderWidth = 1.5
        card.layer.borderColor = UIColor(hex: 0xE5D2C7).cgColor
        card.layer.cornerRadius = 18
        card.translatesAutoresizingMaskIntoConstraints = false

        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(addListTapped), for: .touchUpInside)

        card.addSubview(row)
        card.addSubview(control)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            control.topAnchor.constraint(equalTo: card.topAnchor),
            control.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            control.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            control.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    @objc private func listTapped(_ sender: MilestoneListControl) {
        HapticFeedback.selection()
        navigationController?.pushViewController(MilestoneListDetailViewController(list: sender.list), animated: true)
    }

    @objc private func addListTapped() {
        HapticFeedback.light()
        let alert = UIAlertController(title: "New List", message: "Give your list a name.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "e.g. Grandma's Visit" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self, weak alert] _ in
            guard let self, let name = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return }
            self.store.addList(name: name)
            self.reload()
        })
        present(alert, animated: true)
    }
}

/// Carries the tapped list through the UIControl target/action, which has no payload of its own.
private final class MilestoneListControl: UIControl {
    let list: MilestoneList
    init(list: MilestoneList) {
        self.list = list
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
