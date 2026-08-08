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
            title: NSLocalizedString("Turn your baby's photos into magical keepsakes", comment: "Onboarding page 1 title"),
            subtitle: NSLocalizedString("AI-powered studio portraits in dozens of dreamy themes — created from a single snapshot.", comment: "Onboarding page 1 subtitle"),
            ctaTitle: NSLocalizedString("Get Started", comment: "Onboarding CTA button"),
            showsSkip: true,
            skipColor: UIColor(hex: 0xB98A93),
            shadowColor: UIColor(hex: 0xD68A96)
        ),
        OnboardingPage(
            backgroundGradient: [UIColor(hex: 0xEDE3F7), UIColor(hex: 0xFBE7EE), UIColor(hex: 0xFFF7F0)],
            illustrationName: "OnboardingThemedPortraits",
            title: NSLocalizedString("Dozens of dreamy themes to explore", comment: "Onboarding page 2 title"),
            subtitle: NSLocalizedString("Astronaut, fairy, tiny chef and more — a brand-new studio every single time.", comment: "Onboarding page 2 subtitle"),
            ctaTitle: NSLocalizedString("Next", comment: "Onboarding next button"),
            showsSkip: true,
            skipColor: UIColor(hex: 0xA98BB4),
            shadowColor: UIColor(hex: 0x9678BE)
        ),
        OnboardingPage(
            backgroundGradient: [UIColor(hex: 0xE0F1E9), UIColor(hex: 0xFBE7EE), UIColor(hex: 0xFFF7F0)],
            illustrationName: "OnboardingMilestoneAlbum",
            title: NSLocalizedString("Capture every milestone in one place", comment: "Onboarding page 3 title"),
            subtitle: NSLocalizedString("Track baby's firsts and keep every precious memory beautifully organized.", comment: "Onboarding page 3 subtitle"),
            ctaTitle: NSLocalizedString("Get Started", comment: "Onboarding CTA button"),
            showsSkip: false,
            skipColor: .clear,
            shadowColor: UIColor(hex: 0x78B496)
        )
    ]
}
