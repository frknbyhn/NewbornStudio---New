import UIKit

/// Threaded through GenerationLoadingViewController -> ResultViewController so closing the
/// result screen can save it onto the right milestone/list and navigate back there, instead of
/// the default popToRoot.
struct MilestoneCaptureContext {
    let milestoneId: String
    let listId: String
}

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
    /// Populated immediately after a local pick/generation (no network round trip needed to
    /// show it); `photoUrl` is the durable Firebase Storage URL backing it, used to redisplay
    /// after a relaunch (see MilestoneStore/MilestoneRemoteStore) since UIImage itself is never
    /// persisted.
    var photo: UIImage?
    var photoUrl: String?

    init(id: String = UUID().uuidString, title: String, state: State = .pending, group: String? = nil, style: Style = .default, aiPrompt: String? = nil, photo: UIImage? = nil, photoUrl: String? = nil) {
        self.id = id
        self.title = title
        self.state = state
        self.group = group
        self.style = style
        self.aiPrompt = aiPrompt
        self.photo = photo
        self.photoUrl = photoUrl
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
        name: "Firsts",
        isStandard: true,
        milestones: [
            // Ids match the "Milestones" theme_catalog.json category's style ids exactly — lets
            // ResultViewController match a generated result (by theme.id) back to the milestone
            // it belongs to when the user reaches it via Home's Milestones category instead of
            // MilestoneCaptureViewController. Keep both in sync if either changes.
            Milestone(id: "milestone-first-smile", title: "First Smile", group: "Firsts", style: .pink.with(icon: "face.smiling"), aiPrompt: "Add a soft golden glow and gentle bokeh sparkles around my baby's smiling face, dreamy studio portrait style."),
            Milestone(id: "milestone-first-laugh", title: "First Laugh", group: "Firsts", style: .pink.with(icon: "sparkles"), aiPrompt: "Capture the joy with warm sunlight rays and floating sparkles around my laughing baby."),
            Milestone(id: "milestone-first-bath", title: "First Bath", group: "Firsts", style: .mint.with(icon: "drop.fill"), aiPrompt: "Transform into a dreamy bath-time scene with soft bubbles, warm pastel tones, and a cozy towel."),
            Milestone(id: "milestone-first-outing", title: "First Outing", group: "Firsts", style: .purple.with(icon: "figure.walk"), aiPrompt: "Add a whimsical sunny park background with soft bokeh and a gentle breeze feel."),
            Milestone(id: "milestone-first-studio-portrait", title: "First Studio Portrait", group: "Firsts", style: .purple.with(icon: "camera.fill"), aiPrompt: "Give this a professional warm studio portrait look with a soft creamy backdrop and gentle lighting."),

            Milestone(id: "milestone-holds-head-up", title: "Holds Head Up", group: "Growth & Motor Skills", style: .gold.with(icon: "arrow.up.circle.fill"), aiPrompt: "Add a soft pastel nursery backdrop with gentle light rays celebrating this proud moment."),
            Milestone(id: "milestone-rolls-over", title: "Rolls Over", group: "Growth & Motor Skills", style: .purple.with(icon: "arrow.triangle.2.circlepath"), aiPrompt: "Add a playful pastel-colored play mat background with soft clouds and stars."),
            Milestone(id: "milestone-sits-up-unassisted", title: "Sits Up Unassisted", group: "Growth & Motor Skills", style: .mint.with(icon: "figure.stand"), aiPrompt: "Add a cozy soft-cushioned nursery corner background celebrating this milestone."),
            Milestone(id: "milestone-crawls", title: "Crawls", group: "Growth & Motor Skills", style: .gold.with(icon: "tortoise.fill"), aiPrompt: "Add a whimsical adventure-themed background with a soft pastel trail and playful clouds."),
            Milestone(id: "milestone-pulls-to-stand", title: "Pulls to Stand", group: "Growth & Motor Skills", style: .purple.with(icon: "arrow.up.to.line"), aiPrompt: "Add a warm golden-hour glow behind my baby standing proudly, soft dreamy background."),
            Milestone(id: "milestone-first-steps", title: "First Steps", group: "Growth & Motor Skills", style: .gold.with(icon: "flag.checkered"), aiPrompt: "Add a magical path of soft glowing stepping stones and warm sunset colors."),
            Milestone(id: "milestone-walks-independently", title: "Walks Independently", group: "Growth & Motor Skills", style: .pink.with(icon: "bolt.fill"), aiPrompt: "Add a joyful confetti-filled celebratory background with warm bokeh lights."),

            Milestone(id: "milestone-coos-babbles", title: "Coos & Babbles", group: "Communication", style: .purple.with(icon: "bubble.left.and.bubble.right.fill"), aiPrompt: "Add soft floating musical notes and a dreamy pastel background."),
            Milestone(id: "milestone-says-first-word", title: "Says First Word", group: "Communication", style: .pink.with(icon: "text.bubble.fill"), aiPrompt: "Add gentle speech-bubble sparkles and a warm cozy background celebrating this moment."),
            Milestone(id: "milestone-waves-bye-bye", title: "Waves Bye-Bye", group: "Communication", style: .gold.with(icon: "hand.wave.fill"), aiPrompt: "Add a soft sunset background with warm golden light, as if waving goodbye at dusk."),

            Milestone(id: "milestone-first-tooth", title: "First Tooth", group: "Body", style: .pink.with(icon: "checkmark.seal.fill"), aiPrompt: "Add a playful sparkle and a soft pastel background celebrating the first tooth."),
            Milestone(id: "milestone-first-haircut", title: "First Haircut", group: "Body", style: .mint.with(icon: "scissors"), aiPrompt: "Add a charming little barbershop-style backdrop with soft warm tones."),

            Milestone(id: "milestone-sleeps-through-night", title: "Sleeps Through the Night", group: "Celebrations", style: .purple.with(icon: "moon.zzz.fill"), aiPrompt: "Add a dreamy starry night sky background with a soft moonlight glow."),
            Milestone(id: "milestone-first-holiday-season", title: "First Holiday Season", group: "Celebrations", style: .gold.with(icon: "gift.fill"), aiPrompt: "Add a cozy festive holiday background with warm twinkling lights."),
            Milestone(id: "milestone-first-birthday", title: "First Birthday", group: "Celebrations", style: .gold.with(icon: "star.fill"), aiPrompt: "Add a joyful birthday party background with soft pastel balloons and confetti.")
        ]
    )

    /// Second always-present standard list — same working logic as `.standard` (auto-populated
    /// for every user, capture-only, no add/remove), documenting the baby's monthly growth from
    /// one week to one year old. Ids match the "Milestones" (age-milestones) theme_catalog.json
    /// category's style ids exactly, same reasoning as `.standard` above — lets a Home-category
    /// generation of one of these styles auto-match back to its milestone here.
    static let ageJourney = MilestoneList(
        id: "age-milestones",
        name: "Milestones",
        isStandard: true,
        milestones: [
            Milestone(id: "age-one-week", title: "One Week", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden 'ONE WEEK' milestone marker and a few dried flowers beside me, soft cream blanket, natural window light, minimalist newborn documentary style."),
            Milestone(id: "age-one-month", title: "One Month", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '1 MONTH' milestone marker and a few dried flowers beside me, soft cream blanket, natural light, clean growth-journal style."),
            Milestone(id: "age-two-months", title: "Two Months", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '2 MONTHS' milestone marker and a few dried flowers beside me, soft cream blanket, alert and curious expression, natural light."),
            Milestone(id: "age-three-months", title: "Three Months", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '3 MONTHS' milestone marker and a few dried flowers beside me during gentle tummy time, soft cream blanket, natural light."),
            Milestone(id: "age-four-months", title: "Four Months", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '4 MONTHS' milestone marker and a few dried flowers beside me, propped up on tiny arms during tummy time, natural light."),
            Milestone(id: "age-five-months", title: "Five Months", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '5 MONTHS' milestone marker surrounded by a few dried flowers, reaching toward it on a soft cream blanket, natural light."),
            Milestone(id: "age-six-months", title: "Six Months", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '6 MONTHS' milestone marker and a few dried flowers beside me, sitting propped up on soft cushions, natural light."),
            Milestone(id: "age-seven-months", title: "Seven Months", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '7 MONTHS' milestone marker and a few dried flowers beside me, sitting upright with light support, natural light."),
            Milestone(id: "age-eight-months", title: "Eight Months", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '8 MONTHS' milestone marker and a few dried flowers beside me, sitting confidently, natural light."),
            Milestone(id: "age-nine-months", title: "Nine Months", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '9 MONTHS' milestone marker surrounded by a few dried flowers, sitting independently and reaching for it, natural light."),
            Milestone(id: "age-ten-months", title: "Ten Months", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '10 MONTHS' milestone marker and a few dried flowers beside me, on all fours, natural light."),
            Milestone(id: "age-eleven-months", title: "Eleven Months", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '11 MONTHS' milestone marker and a few dried flowers beside me, pulling up to stand, natural light."),
            Milestone(id: "age-one-year", title: "One Year", style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '1 YEAR' milestone marker amid a small first-birthday-style arrangement of dried flowers and a single balloon, standing proudly, natural light, joyful celebratory tone.")
        ]
    )
}
