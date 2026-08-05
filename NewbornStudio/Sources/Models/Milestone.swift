import Foundation

struct Milestone: Identifiable {
    enum State { case done, pending }
    let id: String
    var title: String
    var state: State
    /// Section header for display — only set on the standard list; custom-list milestones are
    /// user-typed and have no predefined grouping.
    var group: String?

    init(id: String = UUID().uuidString, title: String, state: State = .pending, group: String? = nil) {
        self.id = id
        self.title = title
        self.state = state
        self.group = group
    }
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
            Milestone(title: "First Smile", group: "Firsts"),
            Milestone(title: "First Laugh", group: "Firsts"),
            Milestone(title: "First Bath", group: "Firsts"),
            Milestone(title: "First Outing", group: "Firsts"),
            Milestone(title: "First Studio Portrait", group: "Firsts"),

            Milestone(title: "Holds Head Up", group: "Growth & Motor Skills"),
            Milestone(title: "Rolls Over", group: "Growth & Motor Skills"),
            Milestone(title: "Sits Up Unassisted", group: "Growth & Motor Skills"),
            Milestone(title: "Crawls", group: "Growth & Motor Skills"),
            Milestone(title: "Pulls to Stand", group: "Growth & Motor Skills"),
            Milestone(title: "First Steps", group: "Growth & Motor Skills"),
            Milestone(title: "Walks Independently", group: "Growth & Motor Skills"),

            Milestone(title: "Coos & Babbles", group: "Communication"),
            Milestone(title: "Says First Word", group: "Communication"),
            Milestone(title: "Waves Bye-Bye", group: "Communication"),

            Milestone(title: "First Tooth", group: "Body"),
            Milestone(title: "First Haircut", group: "Body"),

            Milestone(title: "Sleeps Through the Night", group: "Celebrations"),
            Milestone(title: "First Holiday Season", group: "Celebrations"),
            Milestone(title: "First Birthday", group: "Celebrations")
        ]
    )
}
