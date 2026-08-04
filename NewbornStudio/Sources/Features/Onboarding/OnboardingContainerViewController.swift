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
        vc.onContinue = { [weak self] in self?.advance(from: index) }
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(pageViewController)
        pageViewController.view.frame = view.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        pageViewController.dataSource = self
        if let first = pages.first {
            pageViewController.setViewControllers([first], direction: .forward, animated: false)
        }
    }

    private func advance(from index: Int) {
        guard index + 1 < pages.count else {
            finish()
            return
        }
        pageViewController.setViewControllers([pages[index + 1]], direction: .forward, animated: true)
    }

    private func finish() {
        onFinished?()
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
