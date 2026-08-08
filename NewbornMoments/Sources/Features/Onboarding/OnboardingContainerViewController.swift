import UIKit

final class OnboardingContainerViewController: UIViewController {
    var onFinished: (() -> Void)?

    private let pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )
    private lazy var pages: [OnboardingPageViewController] = OnboardingPage.all.enumerated().map { index, page in
        let vc = OnboardingPageViewController(page: page, pageIndex: index, totalPages: OnboardingPage.all.count)
        vc.onSkip = { [weak self] in self?.finish() }
        return vc
    }

    // Persistent overlay — sibling of the page view controller's view, added on top and never
    // part of the per-page content, so it never slides with the horizontal page transition.
    private let dots = PageDotsView(count: OnboardingPage.all.count)
    private let cta = GradientPillButton(title: "")
    private var currentIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(pageViewController)
        pageViewController.view.frame = view.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        if let first = pages.first {
            pageViewController.setViewControllers([first], direction: .forward, animated: false)
        }
        setUpPersistentControls()
        updateControls(for: 0)
    }

    private func setUpPersistentControls() {
        cta.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
        cta.translatesAutoresizingMaskIntoConstraints = false

        let bottomStack = UIStackView(arrangedSubviews: [dots, cta])
        bottomStack.axis = .vertical
        bottomStack.alignment = .center
        bottomStack.spacing = 26
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomStack)

        NSLayoutConstraint.activate([
            bottomStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            bottomStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),
            bottomStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cta.leadingAnchor.constraint(equalTo: bottomStack.leadingAnchor),
            cta.trailingAnchor.constraint(equalTo: bottomStack.trailingAnchor)
        ])
    }

    private func updateControls(for index: Int) {
        currentIndex = index
        dots.activeIndex = index
        cta.title = pages[index].page.ctaTitle
    }

    @objc private func ctaTapped() {
        HapticFeedback.light()
        advance(from: currentIndex)
    }

    private func advance(from index: Int) {
        guard index + 1 < pages.count else {
            finish()
            return
        }
        pageViewController.setViewControllers([pages[index + 1]], direction: .forward, animated: true)
        updateControls(for: index + 1)
    }

    private func finish() {
        onFinished?()
    }
}

extension OnboardingContainerViewController: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed, let current = pageViewController.viewControllers?.first as? OnboardingPageViewController else { return }
        updateControls(for: current.pageIndex)
    }
}

extension OnboardingContainerViewController: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let current = viewController as? OnboardingPageViewController, current.pageIndex > 0 else { return nil }
        return pages[current.pageIndex - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let current = viewController as? OnboardingPageViewController, current.pageIndex + 1 < pages.count else { return nil }
        return pages[current.pageIndex + 1]
    }
}
