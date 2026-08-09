import UIKit

/// Full list of every language the app supports (see LanguageManager.supported). Tapping a row
/// applies it instantly — no relaunch — via LanguageManager.setLanguage, which rebuilds the
/// whole app UI in place.
///
/// Custom header bar (not the system nav bar) to match every other pushed screen in the tab
/// shell — MainTabBarController hides the UINavigationController's own bar, see CategoryStylesViewController.
final class LanguageListViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let cellId = "LanguageCell"
    private var navBarBottom: NSLayoutYAxisAnchor!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.backgroundCream
        setUpNavBar()
        setUpTable()
    }

    private func setUpNavBar() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        back.tintColor = Theme.Color.textSecondaryAlt
        back.backgroundColor = Theme.Color.backgroundWarm
        back.layer.cornerRadius = 12
        back.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        back.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = NSLocalizedString("Language", comment: "Language picker screen title")
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

    private func setUpTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: navBarBottom, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension LanguageListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        LanguageManager.supported.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let entry = LanguageManager.supported[indexPath.row]
        var config = UIListContentConfiguration.cell()
        config.text = entry.name
        config.textProperties.font = Theme.Font.body(15, weight: 600)
        cell.contentConfiguration = config
        cell.backgroundColor = .white
        cell.accessoryType = entry.code == LanguageManager.currentCode ? .checkmark : .none
        cell.tintColor = Theme.Color.accentEnd
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entry = LanguageManager.supported[indexPath.row]
        guard entry.code != LanguageManager.currentCode else { return }
        HapticFeedback.selection()
        // AppCoordinator.reloadForLanguageChange() (triggered inside setLanguage) rebuilds the
        // whole window from scratch, so this screen doesn't need to dismiss/pop itself — it's
        // simply replaced along with everything else, landing back on Profile in the new language.
        LanguageManager.setLanguage(entry.code)
    }
}
