import UIKit

struct Milestone: Identifiable {
    enum State { case done, pending }

    /// Icon + tint/ink for the detail screen's icon tile — mirrors the Milestone Tracker mockup
    /// (Design/Newborn Studio.dc.html, section 7), which pairs each milestone with its own
    /// colored icon tile rather than a plain row.
    struct Style {
        let icon: String
        let tint: UIColor
        let ink: UIColor
    }

    let id: String
    var title: String
    var state: State
    /// Section header for display — only set on the standard list; custom-list milestones are
    /// user-typed and have no predefined grouping.
    var group: String?
    var style: Style
    /// Pre-fills the capture screen's prompt field for standard milestones (see
    /// MilestoneCaptureViewController) — nil for custom, user-typed milestones since there's no
    /// curated idea to suggest.
    var aiPrompt: String?
    /// Set once the milestone is captured — the actual photo (or AI result) the user saved.
    var photo: UIImage?

    init(id: String = UUID().uuidString, title: String, state: State = .pending, group: String? = nil, style: Style = .default, aiPrompt: String? = nil, photo: UIImage? = nil) {
        self.id = id
        self.title = title
        self.state = state
        self.group = group
        self.style = style
        self.aiPrompt = aiPrompt
        self.photo = photo
    }
}

extension Milestone.Style {
    static let pink = Milestone.Style(icon: "star.fill", tint: UIColor(hex: 0xFCE6EC), ink: Theme.Color.accentEnd)
    static let purple = Milestone.Style(icon: "star.fill", tint: Theme.Color.purpleBackground, ink: Theme.Color.purpleAccent)
    static let mint = Milestone.Style(icon: "star.fill", tint: Theme.Color.successBackground, ink: Theme.Color.success)
    static let gold = Milestone.Style(icon: "star.fill", tint: Theme.Color.coinBackground, ink: Theme.Color.coin)
    /// Custom-list milestones are user-typed with no curated icon, so they fall back to this.
    static let `default` = Milestone.Style(icon: "star.fill", tint: Theme.Color.backgroundWarm, ink: Theme.Color.textSecondaryAlt)

    func with(icon: String) -> Milestone.Style { Milestone.Style(icon: icon, tint: tint, ink: ink) }
}

struct MilestoneList: Identifiable {
    let id: String
    var name: String
    /// The curated, app-provided list — its milestones can't be added to or removed by the user.
    let isStandard: Bool
    var milestones: [Milestone]

    static let standard = MilestoneList(
        id: "standard",
        name: "Standard Milestones",
        isStandard: true,
        milestones: [
            Milestone(title: "First Smile", group: "Firsts", style: .pink.with(icon: "face.smiling"), aiPrompt: "Add a soft golden glow and gentle bokeh sparkles around my baby's smiling face, dreamy studio portrait style."),
            Milestone(title: "First Laugh", group: "Firsts", style: .pink.with(icon: "sparkles"), aiPrompt: "Capture the joy with warm sunlight rays and floating sparkles around my laughing baby."),
            Milestone(title: "First Bath", group: "Firsts", style: .mint.with(icon: "drop.fill"), aiPrompt: "Transform into a dreamy bath-time scene with soft bubbles, warm pastel tones, and a cozy towel."),
            Milestone(title: "First Outing", group: "Firsts", style: .purple.with(icon: "figure.walk"), aiPrompt: "Add a whimsical sunny park background with soft bokeh and a gentle breeze feel."),
            Milestone(title: "First Studio Portrait", group: "Firsts", style: .purple.with(icon: "camera.fill"), aiPrompt: "Give this a professional warm studio portrait look with a soft creamy backdrop and gentle lighting."),

            Milestone(title: "Holds Head Up", group: "Growth & Motor Skills", style: .gold.with(icon: "arrow.up.circle.fill"), aiPrompt: "Add a soft pastel nursery backdrop with gentle light rays celebrating this proud moment."),
            Milestone(title: "Rolls Over", group: "Growth & Motor Skills", style: .purple.with(icon: "arrow.triangle.2.circlepath"), aiPrompt: "Add a playful pastel-colored play mat background with soft clouds and stars."),
            Milestone(title: "Sits Up Unassisted", group: "Growth & Motor Skills", style: .mint.with(icon: "figure.stand"), aiPrompt: "Add a cozy soft-cushioned nursery corner background celebrating this milestone."),
            Milestone(title: "Crawls", group: "Growth & Motor Skills", style: .gold.with(icon: "tortoise.fill"), aiPrompt: "Add a whimsical adventure-themed background with a soft pastel trail and playful clouds."),
            Milestone(title: "Pulls to Stand", group: "Growth & Motor Skills", style: .purple.with(icon: "arrow.up.to.line"), aiPrompt: "Add a warm golden-hour glow behind my baby standing proudly, soft dreamy background."),
            Milestone(title: "First Steps", group: "Growth & Motor Skills", style: .gold.with(icon: "flag.checkered"), aiPrompt: "Add a magical path of soft glowing stepping stones and warm sunset colors."),
            Milestone(title: "Walks Independently", group: "Growth & Motor Skills", style: .pink.with(icon: "bolt.fill"), aiPrompt: "Add a joyful confetti-filled celebratory background with warm bokeh lights."),

            Milestone(title: "Coos & Babbles", group: "Communication", style: .purple.with(icon: "bubble.left.and.bubble.right.fill"), aiPrompt: "Add soft floating musical notes and a dreamy pastel background."),
            Milestone(title: "Says First Word", group: "Communication", style: .pink.with(icon: "text.bubble.fill"), aiPrompt: "Add gentle speech-bubble sparkles and a warm cozy background celebrating this moment."),
            Milestone(title: "Waves Bye-Bye", group: "Communication", style: .gold.with(icon: "hand.wave.fill"), aiPrompt: "Add a soft sunset background with warm golden light, as if waving goodbye at dusk."),

            Milestone(title: "First Tooth", group: "Body", style: .pink.with(icon: "checkmark.seal.fill"), aiPrompt: "Add a playful sparkle and a soft pastel background celebrating the first tooth."),
            Milestone(title: "First Haircut", group: "Body", style: .mint.with(icon: "scissors"), aiPrompt: "Add a charming little barbershop-style backdrop with soft warm tones."),

            Milestone(title: "Sleeps Through the Night", group: "Celebrations", style: .purple.with(icon: "moon.zzz.fill"), aiPrompt: "Add a dreamy starry night sky background with a soft moonlight glow."),
            Milestone(title: "First Holiday Season", group: "Celebrations", style: .gold.with(icon: "gift.fill"), aiPrompt: "Add a cozy festive holiday background with warm twinkling lights."),
            Milestone(title: "First Birthday", group: "Celebrations", style: .gold.with(icon: "star.fill"), aiPrompt: "Add a joyful birthday party background with soft pastel balloons and confetti.")
        ]
    )
}
