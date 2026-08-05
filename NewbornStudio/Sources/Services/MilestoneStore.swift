import UIKit

/// In-memory only for now — session-scoped, not persisted to Firestore yet (that's a later pass,
/// see `users/{uid}/milestones/{id}` already reserved in the schema). Holds the always-present
/// standard list plus any lists the user creates.
final class MilestoneStore {
    static let shared = MilestoneStore()

    private(set) var lists: [MilestoneList] = [.standard]

    private init() {}

    func addList(name: String) {
        lists.append(MilestoneList(id: UUID().uuidString, name: name, isStandard: false, milestones: []))
    }

    func addMilestone(title: String, toListId listId: String) {
        guard let index = lists.firstIndex(where: { $0.id == listId }), !lists[index].isStandard else { return }
        lists[index].milestones.append(Milestone(title: title))
    }

    func removeMilestone(id milestoneId: String, fromListId listId: String) {
        guard let index = lists.firstIndex(where: { $0.id == listId }), !lists[index].isStandard else { return }
        lists[index].milestones.removeAll { $0.id == milestoneId }
    }

    /// Marks a milestone captured with a photo — allowed on standard milestones too (unlike
    /// add/removeMilestone), since completing one is the whole point of the standard list.
    func capture(photo: UIImage, forMilestoneId milestoneId: String, inListId listId: String) {
        guard let listIndex = lists.firstIndex(where: { $0.id == listId }),
              let milestoneIndex = lists[listIndex].milestones.firstIndex(where: { $0.id == milestoneId })
        else { return }
        lists[listIndex].milestones[milestoneIndex].state = .done
        lists[listIndex].milestones[milestoneIndex].photo = photo
    }
}
