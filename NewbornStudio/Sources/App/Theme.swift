import UIKit
import CoreText

/// Design tokens extracted from the Claude Design mockups (Design/Newborn Studio.dc.html).
enum Theme {
    enum Color {
        // Accent — pink/rose gradient
        static let accentStart = UIColor(hex: 0xF4A6B3)
        static let accentEnd = UIColor(hex: 0xE5738D)

        // Backgrounds
        static let backgroundCream = UIColor(hex: 0xFFFBF7)
        static let backgroundWarm = UIColor(hex: 0xF6EFEA)
        static let backgroundTaupe = UIColor(hex: 0xE9E2DA)

        // Text
        static let textPrimary = UIColor(hex: 0x463A3F)
        static let textPrimaryAlt = UIColor(hex: 0x4A3F44)
        static let textSecondary = UIColor(hex: 0xA38C90)
        static let textSecondaryAlt = UIColor(hex: 0x8C7D80)

        // Semantic
        static let success = UIColor(hex: 0x4FA07C)
        static let successBackground = UIColor(hex: 0xE0F3EA)
        static let coin = UIColor(hex: 0xE8A93C)
        static let coinBackground = UIColor(hex: 0xFFF3D9)
        static let purpleAccent = UIColor(hex: 0x7A63C4)
        static let purpleBackground = UIColor(hex: 0xEDE7FB)

        static let accentGradient = [accentStart.cgColor, accentEnd.cgColor]
    }

    enum Font {
        // Quicksand — headings. Nunito — body text. Both are variable fonts (single 'wght' axis);
        // the exact weight is dialed in via the CoreText variation attribute, not separate font files.
        // Registered in Info.plist (UIAppFonts) as Quicksand-Light.ttf / Nunito-ExtraLight.ttf (their default-instance PostScript names).
        static func heading(_ size: CGFloat, weight: CGFloat = 700) -> UIFont {
            variableFont(postscriptName: "Quicksand-Light", size: size, weight: weight)
        }

        static func body(_ size: CGFloat, weight: CGFloat = 400) -> UIFont {
            variableFont(postscriptName: "Nunito-ExtraLight", size: size, weight: weight)
        }

        // Standard OpenType 'wght' axis tag as a four-char-code integer.
        private static let wghtAxisIdentifier: Int = 0x77676874

        private static func variableFont(postscriptName: String, size: CGFloat, weight: CGFloat) -> UIFont {
            let baseDescriptor = UIFontDescriptor(name: postscriptName, size: size)
            guard UIFont(descriptor: baseDescriptor, size: size).fontName.lowercased().contains(postscriptName.split(separator: "-").first!.lowercased()) else {
                return .systemFont(ofSize: size)
            }
            let variationAttribute = kCTFontVariationAttribute as UIFontDescriptor.AttributeName
            let descriptor = baseDescriptor.addingAttributes([variationAttribute: [wghtAxisIdentifier: weight]])
            return UIFont(descriptor: descriptor, size: size)
        }
    }

    enum Shape {
        static let cardRadius: CGFloat = 22
        static let sheetRadius: CGFloat = 26
        static let pillRadius: CGFloat = 100
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension CAGradientLayer {
    static func accentPill() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = Theme.Color.accentGradient
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }
}

extension String {
    /// How many lines this string wraps to at a given width/font — lets a grid cell's
    /// sizeForItemAt give a 1-line title a shorter cell than a 2-line one, instead of every
    /// cell paying the worst-case height regardless of its own text.
    func lineCount(font: UIFont, width: CGFloat, maxLines: Int) -> Int {
        guard width > 0 else { return 1 }
        let bounds = CGSize(width: width, height: .greatestFiniteMagnitude)
        let rect = (self as NSString).boundingRect(
            with: bounds,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        let lines = max(1, Int(ceil(rect.height / font.lineHeight)))
        return min(lines, maxLines)
    }
}
