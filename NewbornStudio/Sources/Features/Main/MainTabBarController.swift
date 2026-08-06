import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let home = wrap(HomeViewController(), title: "Home", icon: "house.fill")
        let milestones = wrap(MilestoneListsViewController(), title: "My Collages", icon: "film.stack.fill")
        let gallery = wrap(GalleryViewController(), title: "Gallery", icon: "photo.on.rectangle")
        let profile = wrap(ProfileViewController(), title: "Profile", icon: "person.fill")

        viewControllers = [home, milestones, gallery, profile]

        tabBar.tintColor = Theme.Color.accentEnd
        tabBar.unselectedItemTintColor = UIColor(hex: 0xBEB3B0)
        tabBar.backgroundColor = .white
        tabBar.isTranslucent = false

        #if DEBUG
        if let tabIndex = ProcessInfo.processInfo.environment["NS_DEBUG_TAB"].flatMap(Int.init) {
            selectedIndex = tabIndex
        }
        #endif
    }

    private static var nextTag = 0

    private func wrap(_ root: UIViewController, title: String, icon: String) -> UIViewController {
        let nav = UINavigationController(rootViewController: root)
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: icon), tag: Self.nextTag)
        Self.nextTag += 1
        nav.navigationBar.isHidden = true
        return nav
    }
}
