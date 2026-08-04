import Foundation

struct Milestone {
    enum State { case done, pending }
    let title: String
    let state: State

    static let samples: [Milestone] = [
        Milestone(title: "First smile", state: .done),
        Milestone(title: "First studio portrait", state: .done),
        Milestone(title: "First laugh", state: .pending),
        Milestone(title: "First birthday", state: .pending)
    ]
}
