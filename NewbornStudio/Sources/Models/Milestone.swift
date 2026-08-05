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

    init(id: String = UUID().uuidString, title: String, state: State = .pending, group: String? = nil, style: Style = .default) {
        self.id = id
        self.title = title
        self.state = state
        self.group = group
        self.style = style
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
            Milestone(title: "First Smile", group: "Firsts", style: .pink.with(icon: "face.smiling")),
            Milestone(title: "First Laugh", group: "Firsts", style: .pink.with(icon: "sparkles")),
            Milestone(title: "First Bath", group: "Firsts", style: .mint.with(icon: "drop.fill")),
            Milestone(title: "First Outing", group: "Firsts", style: .purple.with(icon: "figure.walk")),
            Milestone(title: "First Studio Portrait", group: "Firsts", style: .purple.with(icon: "camera.fill")),

            Milestone(title: "Holds Head Up", group: "Growth & Motor Skills", style: .gold.with(icon: "arrow.up.circle.fill")),
            Milestone(title: "Rolls Over", group: "Growth & Motor Skills", style: .purple.with(icon: "arrow.triangle.2.circlepath")),
            Milestone(title: "Sits Up Unassisted", group: "Growth & Motor Skills", style: .mint.with(icon: "figure.stand")),
            Milestone(title: "Crawls", group: "Growth & Motor Skills", style: .gold.with(icon: "tortoise.fill")),
            Milestone(title: "Pulls to Stand", group: "Growth & Motor Skills", style: .purple.with(icon: "arrow.up.to.line")),
            Milestone(title: "First Steps", group: "Growth & Motor Skills", style: .gold.with(icon: "flag.checkered")),
            Milestone(title: "Walks Independently", group: "Growth & Motor Skills", style: .pink.with(icon: "bolt.fill")),

            Milestone(title: "Coos & Babbles", group: "Communication", style: .purple.with(icon: "bubble.left.and.bubble.right.fill")),
            Milestone(title: "Says First Word", group: "Communication", style: .pink.with(icon: "text.bubble.fill")),
            Milestone(title: "Waves Bye-Bye", group: "Communication", style: .gold.with(icon: "hand.wave.fill")),

            Milestone(title: "First Tooth", group: "Body", style: .pink.with(icon: "checkmark.seal.fill")),
            Milestone(title: "First Haircut", group: "Body", style: .mint.with(icon: "scissors")),

            Milestone(title: "Sleeps Through the Night", group: "Celebrations", style: .purple.with(icon: "moon.zzz.fill")),
            Milestone(title: "First Holiday Season", group: "Celebrations", style: .gold.with(icon: "gift.fill")),
            Milestone(title: "First Birthday", group: "Celebrations", style: .gold.with(icon: "star.fill"))
        ]
    )
}
