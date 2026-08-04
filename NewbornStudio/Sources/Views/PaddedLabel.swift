import UIKit

/// A UILabel with real horizontal padding baked into its intrinsic content size — used for pill-shaped badges/chips.
final class PaddedLabel: UILabel {
    var horizontalPadding: CGFloat = 12

    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(width: base.width + horizontalPadding * 2, height: base.height)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: horizontalPadding, dy: 0))
    }
}
