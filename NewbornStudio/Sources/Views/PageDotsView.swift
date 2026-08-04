import UIKit

final class PageDotsView: UIView {
    private var dots: [UIView] = []
    private var dotWidthConstraints: [NSLayoutConstraint] = []
    private let count: Int
    var activeIndex: Int = 0 {
        didSet { updateDots() }
    }

    init(count: Int) {
        self.count = count
        super.init(frame: .zero)
        setUp()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUp() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        for _ in 0..<count {
            let dot = UIView()
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
            let widthConstraint = dot.widthAnchor.constraint(equalToConstant: 8)
            widthConstraint.isActive = true
            stack.addArrangedSubview(dot)
            dots.append(dot)
            dotWidthConstraints.append(widthConstraint)
        }
        updateDots()
    }

    private func updateDots() {
        for (index, dot) in dots.enumerated() {
            let isActive = index == activeIndex
            dotWidthConstraints[index].constant = isActive ? 26 : 8
            dot.backgroundColor = isActive ? Theme.Color.accentEnd : UIColor(hex: 0xEFC9D1)
        }
        layoutIfNeeded()
    }
}
