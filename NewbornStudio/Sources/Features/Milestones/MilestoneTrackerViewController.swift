import UIKit

/// Private to the user — never shared, no social layer (per product decision, see DECISIONS.md).
final class MilestoneTrackerViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpHeader()
        setUpList()
    }

    private var headerBottom: NSLayoutYAxisAnchor!

    private func setUpHeader() {
        let title = UILabel()
        title.text = "Your baby's milestones"
        title.font = Theme.Font.heading(23, weight: 700)
        title.textColor = Theme.Color.textPrimaryAlt

        let done = Milestone.samples.filter { $0.state == .done }.count
        let subtitle = UILabel()
        subtitle.text = "\(done) of \(Milestone.samples.count) captured this year"
        subtitle.font = Theme.Font.body(13, weight: 600)
        subtitle.textColor = Theme.Color.textSecondary

        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
        headerBottom = stack.bottomAnchor
    }

    private func setUpList() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 24, bottom: 30, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        for milestone in Milestone.samples {
            stack.addArrangedSubview(row(for: milestone))
        }

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: headerBottom, constant: 6),
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

    private func row(for milestone: Milestone) -> UIView {
        let isDone = milestone.state == .done
        let circle = UIView()
        circle.backgroundColor = isDone ? UIColor(hex: 0xF6DCE2) : UIColor(hex: 0xFBF4EF)
        circle.layer.cornerRadius = 27
        if !isDone {
            circle.layer.borderWidth = 2
            circle.layer.borderColor = UIColor(hex: 0xE5D2C7).cgColor
        }
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.widthAnchor.constraint(equalToConstant: 54).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 54).isActive = true

        let icon = UIImageView(image: UIImage(systemName: isDone ? "checkmark" : "plus"))
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

        let row = UIStackView(arrangedSubviews: [circle, label])
        row.axis = .horizontal
        row.spacing = 16
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        return row
    }
}
