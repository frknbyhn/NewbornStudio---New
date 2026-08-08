import UIKit

struct OnboardingPage {
    let backgroundGradient: [UIColor]
    let illustrationName: String
    let title: String
    let subtitle: String
    let ctaTitle: String
    let showsSkip: Bool
    let skipColor: UIColor
    let shadowColor: UIColor

    static let all: [OnboardingPage] = [
        OnboardingPage(
            backgroundGradient: [UIColor(hex: 0xFBE1E7), UIColor(hex: 0xFDEEE4), UIColor(hex: 0xFFF7F0)],
            illustrationName: "OnboardingSleepingBaby",
            title: "Turn your baby's photos into magical keepsakes",
            subtitle: "AI-powered studio portraits in dozens of dreamy themes — created from a single snapshot.",
            ctaTitle: "Get Started",
            showsSkip: true,
            skipColor: UIColor(hex: 0xB98A93),
            shadowColor: UIColor(hex: 0xD68A96)
        ),
        OnboardingPage(
            backgroundGradient: [UIColor(hex: 0xEDE3F7), UIColor(hex: 0xFBE7EE), UIColor(hex: 0xFFF7F0)],
            illustrationName: "OnboardingThemedPortraits",
            title: "Dozens of dreamy themes to explore",
            subtitle: "Astronaut, fairy, tiny chef and more — a brand-new studio every single time.",
            ctaTitle: "Next",
            showsSkip: true,
            skipColor: UIColor(hex: 0xA98BB4),
            shadowColor: UIColor(hex: 0x9678BE)
        ),
        OnboardingPage(
            backgroundGradient: [UIColor(hex: 0xE0F1E9), UIColor(hex: 0xFBE7EE), UIColor(hex: 0xFFF7F0)],
            illustrationName: "OnboardingMilestoneAlbum",
            title: "Capture every milestone in one place",
            subtitle: "Track baby's firsts and keep every precious memory beautifully organized.",
            ctaTitle: "Get Started",
            showsSkip: false,
            skipColor: .clear,
            shadowColor: UIColor(hex: 0x78B496)
        )
    ]
}
