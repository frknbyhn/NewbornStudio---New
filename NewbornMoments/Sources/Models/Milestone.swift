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
    /// Set once, the moment this milestone is first captured — never overwritten by a later
    /// "change photo" (see MilestoneStore.capture). Used by the collage video's date caption and
    /// to order-independently label each card, without needing a server round trip.
    var capturedAt: Date?

    init(id: String = UUID().uuidString, title: String, state: State = .pending, group: String? = nil, style: Style = .default, aiPrompt: String? = nil, photo: UIImage? = nil, photoUrl: String? = nil, capturedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.state = state
        self.group = group
        self.style = style
        self.aiPrompt = aiPrompt
        self.photo = photo
        self.photoUrl = photoUrl
        self.capturedAt = capturedAt
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
        name: NSLocalizedString("Firsts", comment: "Standard milestone list name"),
        isStandard: true,
        milestones: [
            // Ids match the "Milestones" theme_catalog.json category's style ids exactly — lets
            // ResultViewController match a generated result (by theme.id) back to the milestone
            // it belongs to when the user reaches it via Home's Milestones category instead of
            // MilestoneCaptureViewController. Keep both in sync if either changes.
            // aiPrompt is sent to the AI generation model, never shown to the user — deliberately
            // NOT localized (translating it would change/risk the tuned English prompt wording
            // for no user-visible benefit).
            Milestone(id: "milestone-first-smile", title: NSLocalizedString("First Smile", comment: "Milestone title"), group: NSLocalizedString("Firsts", comment: "Milestone group header"), style: .pink.with(icon: "face.smiling"), aiPrompt: "Change my baby's expression to a joyful gummy smile with eyes gently crinkled, then add a soft golden glow and gentle bokeh sparkles around their face, dreamy studio portrait style."),
            Milestone(id: "milestone-first-laugh", title: NSLocalizedString("First Laugh", comment: "Milestone title"), group: NSLocalizedString("Firsts", comment: "Milestone group header"), style: .pink.with(icon: "sparkles"), aiPrompt: "Change my baby's expression to a big open laugh — eyes crinkled shut, mouth open in delight — then add warm sunbeams and floating golden sparkles around them."),
            Milestone(id: "milestone-first-bath", title: NSLocalizedString("First Bath", comment: "Milestone title"), group: NSLocalizedString("Firsts", comment: "Milestone group header"), style: .mint.with(icon: "drop.fill"), aiPrompt: "Transform into a dreamy bath-time scene: seated in a small vintage-style tub with soft white bubbles, a rubber duck prop nearby, warm diffused light, blush and cream color palette."),
            Milestone(id: "milestone-first-outing", title: NSLocalizedString("First Outing", comment: "Milestone title"), group: NSLocalizedString("Firsts", comment: "Milestone group header"), style: .purple.with(icon: "figure.walk"), aiPrompt: "Add a whimsical sunny park background with soft bokeh and a gentle breeze feel, dressed in a cozy knit sweater as if bundled up for an outing."),
            Milestone(id: "milestone-first-studio-portrait", title: NSLocalizedString("First Studio Portrait", comment: "Milestone title"), group: NSLocalizedString("Firsts", comment: "Milestone group header"), style: .purple.with(icon: "camera.fill"), aiPrompt: "Give this a professional warm studio portrait look — posed on a plush cream faux-fur rug against a soft seamless creamy backdrop, three-point studio lighting with a gentle catchlight in the eyes."),

            Milestone(id: "milestone-holds-head-up", title: NSLocalizedString("Holds Head Up", comment: "Milestone title"), group: NSLocalizedString("Growth & Motor Skills", comment: "Milestone group header"), style: .gold.with(icon: "arrow.up.circle.fill"), aiPrompt: "Change my baby's pose to tummy time, propped up on their little arms with head lifted proudly, then add a soft pastel nursery backdrop with gentle light rays."),
            Milestone(id: "milestone-rolls-over", title: NSLocalizedString("Rolls Over", comment: "Milestone title"), group: NSLocalizedString("Growth & Motor Skills", comment: "Milestone group header"), style: .purple.with(icon: "arrow.triangle.2.circlepath"), aiPrompt: "Change my baby's pose to captured mid-roll from tummy to back, a joyful sense of motion frozen mid-action, on a playful pastel-colored play mat with soft clouds and stars."),
            Milestone(id: "milestone-sits-up-unassisted", title: NSLocalizedString("Sits Up Unassisted", comment: "Milestone title"), group: NSLocalizedString("Growth & Motor Skills", comment: "Milestone group header"), style: .mint.with(icon: "figure.stand"), aiPrompt: "Change my baby's pose to sitting upright fully independently, confident balanced posture, in a cozy soft-cushioned nursery corner."),
            Milestone(id: "milestone-crawls", title: NSLocalizedString("Crawls", comment: "Milestone title"), group: NSLocalizedString("Growth & Motor Skills", comment: "Milestone group header"), style: .gold.with(icon: "tortoise.fill"), aiPrompt: "Change my baby's pose to mid-crawl on all fours with one hand reaching forward, a determined sense of forward motion, on a whimsical adventure-themed pastel trail."),
            Milestone(id: "milestone-pulls-to-stand", title: NSLocalizedString("Pulls to Stand", comment: "Milestone title"), group: NSLocalizedString("Growth & Motor Skills", comment: "Milestone group header"), style: .purple.with(icon: "arrow.up.to.line"), aiPrompt: "Change my baby's pose to standing while holding onto a soft padded ottoman for balance, knees slightly bent in a wobbly but proud stance, warm golden-hour glow behind."),
            Milestone(id: "milestone-first-steps", title: NSLocalizedString("First Steps", comment: "Milestone title"), group: NSLocalizedString("Growth & Motor Skills", comment: "Milestone group header"), style: .gold.with(icon: "flag.checkered"), aiPrompt: "Change my baby's pose to mid-step with one bare foot forward in a wide balancing stance, arms slightly out for balance, on a magical path of soft glowing stepping stones with warm sunset colors."),
            Milestone(id: "milestone-walks-independently", title: NSLocalizedString("Walks Independently", comment: "Milestone title"), group: NSLocalizedString("Growth & Motor Skills", comment: "Milestone group header"), style: .pink.with(icon: "bolt.fill"), aiPrompt: "Change my baby's pose to walking confidently with arms slightly raised for balance and a big proud smile, joyful confetti-filled celebratory background with warm bokeh lights."),

            Milestone(id: "milestone-coos-babbles", title: NSLocalizedString("Coos & Babbles", comment: "Milestone title"), group: NSLocalizedString("Communication", comment: "Milestone group header"), style: .purple.with(icon: "bubble.left.and.bubble.right.fill"), aiPrompt: "Change my baby's expression to mid-coo with an open, expressive little mouth and bright eyes, then add soft floating musical-note illustrations in a dreamy pastel background."),
            Milestone(id: "milestone-says-first-word", title: NSLocalizedString("Says First Word", comment: "Milestone title"), group: NSLocalizedString("Communication", comment: "Milestone group header"), style: .pink.with(icon: "text.bubble.fill"), aiPrompt: "Change my baby's expression to animated and open-mouthed as if mid-word, then add soft pastel speech-bubble sparkle illustrations nearby, warm cozy blurred backdrop."),
            Milestone(id: "milestone-waves-bye-bye", title: NSLocalizedString("Waves Bye-Bye", comment: "Milestone title"), group: NSLocalizedString("Communication", comment: "Milestone group header"), style: .gold.with(icon: "hand.wave.fill"), aiPrompt: "Change my baby's pose so one tiny hand is raised mid-wave near shoulder height, then add a warm golden sunset sky behind them with soft silhouetted clouds and gentle backlighting."),

            Milestone(id: "milestone-first-tooth", title: NSLocalizedString("First Tooth", comment: "Milestone title"), group: NSLocalizedString("Body", comment: "Milestone group header"), style: .pink.with(icon: "checkmark.seal.fill"), aiPrompt: "Change my baby's expression to a gentle open-mouth smile proudly showing a single tiny new tooth, then add a playful soft sparkle accent near the mouth and a cheerful pastel backdrop."),
            Milestone(id: "milestone-first-haircut", title: NSLocalizedString("First Haircut", comment: "Milestone title"), group: NSLocalizedString("Body", comment: "Milestone group header"), style: .mint.with(icon: "scissors"), aiPrompt: "Add a charming little vintage barbershop-style backdrop with soft warm tones, as if seated in a small barber chair."),

            Milestone(id: "milestone-sleeps-through-night", title: NSLocalizedString("Sleeps Through the Night", comment: "Milestone title"), group: NSLocalizedString("Celebrations", comment: "Milestone group header"), style: .purple.with(icon: "moon.zzz.fill"), aiPrompt: "Change my baby's expression to peacefully asleep, eyes gently closed, then add a dreamy starry night sky background with a soft moonlight glow and moonlight-blue bedding."),
            Milestone(id: "milestone-first-holiday-season", title: NSLocalizedString("First Holiday Season", comment: "Milestone title"), group: NSLocalizedString("Celebrations", comment: "Milestone group header"), style: .gold.with(icon: "gift.fill"), aiPrompt: "Add a cozy festive holiday background with warm twinkling lights, dressed in festive-patterned pajamas."),
            Milestone(id: "milestone-first-birthday", title: NSLocalizedString("First Birthday", comment: "Milestone title"), group: NSLocalizedString("Celebrations", comment: "Milestone group header"), style: .gold.with(icon: "star.fill"), aiPrompt: "Change my baby's expression to a big happy smile, then add a joyful birthday party background with soft pastel balloons and confetti.")
        ]
    )

    /// Second always-present standard list — same working logic as `.standard` (auto-populated
    /// for every user, capture-only, no add/remove), documenting the baby's monthly growth from
    /// one week to one year old. Ids match the "Milestones" (age-milestones) theme_catalog.json
    /// category's style ids exactly, same reasoning as `.standard` above — lets a Home-category
    /// generation of one of these styles auto-match back to its milestone here.
    static let ageJourney = MilestoneList(
        id: "age-milestones",
        name: NSLocalizedString("Milestones", comment: "Age-journey milestone list name"),
        isStandard: true,
        milestones: [
            Milestone(id: "age-one-week", title: NSLocalizedString("One Week", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden 'ONE WEEK' milestone marker and a few dried flowers beside me, soft cream blanket, natural window light, minimalist newborn documentary style."),
            Milestone(id: "age-one-month", title: NSLocalizedString("One Month", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '1 MONTH' milestone marker and a few dried flowers beside me, soft cream blanket, natural light, clean growth-journal style."),
            Milestone(id: "age-two-months", title: NSLocalizedString("Two Months", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '2 MONTHS' milestone marker and a few dried flowers beside me, soft cream blanket, alert and curious expression, natural light."),
            Milestone(id: "age-three-months", title: NSLocalizedString("Three Months", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '3 MONTHS' milestone marker and a few dried flowers beside me during gentle tummy time, soft cream blanket, natural light."),
            Milestone(id: "age-four-months", title: NSLocalizedString("Four Months", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '4 MONTHS' milestone marker and a few dried flowers beside me, propped up on tiny arms during tummy time, natural light."),
            Milestone(id: "age-five-months", title: NSLocalizedString("Five Months", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '5 MONTHS' milestone marker surrounded by a few dried flowers, reaching toward it on a soft cream blanket, natural light."),
            Milestone(id: "age-six-months", title: NSLocalizedString("Six Months", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '6 MONTHS' milestone marker and a few dried flowers beside me, sitting propped up on soft cushions, natural light."),
            Milestone(id: "age-seven-months", title: NSLocalizedString("Seven Months", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '7 MONTHS' milestone marker and a few dried flowers beside me, sitting upright with light support, natural light."),
            Milestone(id: "age-eight-months", title: NSLocalizedString("Eight Months", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '8 MONTHS' milestone marker and a few dried flowers beside me, sitting confidently, natural light."),
            Milestone(id: "age-nine-months", title: NSLocalizedString("Nine Months", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '9 MONTHS' milestone marker surrounded by a few dried flowers, sitting independently and reaching for it, natural light."),
            Milestone(id: "age-ten-months", title: NSLocalizedString("Ten Months", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '10 MONTHS' milestone marker and a few dried flowers beside me, on all fours, natural light."),
            Milestone(id: "age-eleven-months", title: NSLocalizedString("Eleven Months", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '11 MONTHS' milestone marker and a few dried flowers beside me, pulling up to stand, natural light."),
            Milestone(id: "age-one-year", title: NSLocalizedString("One Year", comment: "Milestone title"), style: .gold.with(icon: "flag.fill"), aiPrompt: "Add a wooden '1 YEAR' milestone marker amid a small first-birthday-style arrangement of dried flowers and a single balloon, standing proudly, natural light, joyful celebratory tone.")
        ]
    )
}
