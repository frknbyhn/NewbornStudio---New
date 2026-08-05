import UIKit

/// In-memory cache backed by Firestore (see MilestoneRemoteStore) — holds the two always-present
/// standard lists plus any lists the user creates. `lists` is the UI's source of truth (every
/// screen reads it synchronously); every mutating call here also fires a best-effort remote
/// write so the same state is there on the next launch.
final class MilestoneStore {
    static let shared = MilestoneStore()

    private(set) var lists: [MilestoneList] = [.standard, .ageJourney]
    private(set) var hasLoadedRemote = false

    private init() {}

    /// Fetches custom lists + every captured/added milestone from Firestore and merges them
    /// into `lists`, then calls back on the main thread. Safe to call more than once (e.g. every
    /// time the Milestones tab appears) — cheap no-op reads after the first successful load
    /// still refresh state that changed elsewhere (rare, but harmless), and callers should
    /// re-render off the completion regardless.
    func loadFromRemote(completion: @escaping () -> Void) {
        MilestoneRemoteStore.fetchAll { [weak self] result in
            guard let self else { completion(); return }
            if case .success(let payload) = result {
                for meta in payload.lists where !self.lists.contains(where: { $0.id == meta.id }) {
                    self.lists.append(MilestoneList(id: meta.id, name: meta.name, isStandard: false, milestones: []))
                }
                for doc in payload.milestones {
                    guard let listIndex = self.lists.firstIndex(where: { $0.id == doc.listId }) else { continue }
                    if let milestoneIndex = self.lists[listIndex].milestones.firstIndex(where: { $0.id == doc.id }) {
                        // Standard-list item: apply the remote capture onto the hardcoded definition.
                        self.lists[listIndex].milestones[milestoneIndex].state = doc.state == "done" ? .done : .pending
                        self.lists[listIndex].milestones[milestoneIndex].photoUrl = doc.photoUrl
                    } else if !self.lists[listIndex].isStandard {
                        // Custom-list item: the doc IS the definition, reconstruct it.
                        var milestone = Milestone(id: doc.id, title: doc.title ?? "Untitled", state: doc.state == "done" ? .done : .pending)
                        milestone.photoUrl = doc.photoUrl
                        self.lists[listIndex].milestones.append(milestone)
                    }
                }
            }
            self.hasLoadedRemote = true
            DispatchQueue.main.async(execute: completion)
        }
    }

    func addList(name: String) {
        lists.append(MilestoneList(id: UUID().uuidString, name: name, isStandard: false, milestones: []))
        persistCustomLists()
    }

    func addMilestone(title: String, toListId listId: String) {
        guard let index = lists.firstIndex(where: { $0.id == listId }), !lists[index].isStandard else { return }
        let milestone = Milestone(title: title)
        lists[index].milestones.append(milestone)
        MilestoneRemoteStore.saveMilestone(id: milestone.id, listId: listId, title: title, state: .pending, photoUrl: nil)
    }

    func removeMilestone(id milestoneId: String, fromListId listId: String) {
        guard let index = lists.firstIndex(where: { $0.id == listId }), !lists[index].isStandard else { return }
        lists[index].milestones.removeAll { $0.id == milestoneId }
        MilestoneRemoteStore.deleteMilestone(id: milestoneId)
    }

    /// Marks a milestone captured with a photo — allowed on standard milestones too (unlike
    /// add/removeMilestone), since completing one is the whole point of the standard lists.
    ///
    /// `photoUrl` should be passed whenever the photo already has a durable URL (any Wiro/
    /// generateContent result does — see ResultViewController) so no re-upload happens; when nil
    /// (a plain local photo pick with no generation involved), this uploads it to Storage itself
    /// so the capture still survives a relaunch.
    func capture(photo: UIImage, photoUrl: String? = nil, forMilestoneId milestoneId: String, inListId listId: String) {
        guard let listIndex = lists.firstIndex(where: { $0.id == listId }),
              let milestoneIndex = lists[listIndex].milestones.firstIndex(where: { $0.id == milestoneId })
        else { return }
        lists[listIndex].milestones[milestoneIndex].state = .done
        lists[listIndex].milestones[milestoneIndex].photo = photo
        lists[listIndex].milestones[milestoneIndex].photoUrl = photoUrl

        let title = lists[listIndex].isStandard ? nil : lists[listIndex].milestones[milestoneIndex].title
        if let photoUrl {
            MilestoneRemoteStore.saveMilestone(id: milestoneId, listId: listId, title: title, state: .done, photoUrl: photoUrl)
        } else {
            MilestoneRemoteStore.uploadPhoto(photo, milestoneId: milestoneId) { [weak self] uploadedUrl in
                guard let self else { return }
                if let index = self.lists.firstIndex(where: { $0.id == listId }),
                   let mIndex = self.lists[index].milestones.firstIndex(where: { $0.id == milestoneId }) {
                    self.lists[index].milestones[mIndex].photoUrl = uploadedUrl
                }
                MilestoneRemoteStore.saveMilestone(id: milestoneId, listId: listId, title: title, state: .done, photoUrl: uploadedUrl)
            }
        }
    }

    /// Reverts a milestone to not-captured, clearing its photo — used by the milestone detail
    /// screen's delete action. Allowed on standard milestones (deletes the capture, not the
    /// milestone itself) as well as custom ones (deletes the whole item, mirroring removeMilestone).
    func deleteCapture(milestoneId: String, fromListId listId: String) {
        guard let listIndex = lists.firstIndex(where: { $0.id == listId }) else { return }
        if lists[listIndex].isStandard {
            guard let milestoneIndex = lists[listIndex].milestones.firstIndex(where: { $0.id == milestoneId }) else { return }
            lists[listIndex].milestones[milestoneIndex].state = .pending
            lists[listIndex].milestones[milestoneIndex].photo = nil
            lists[listIndex].milestones[milestoneIndex].photoUrl = nil
            MilestoneRemoteStore.deleteMilestone(id: milestoneId)
        } else {
            removeMilestone(id: milestoneId, fromListId: listId)
        }
    }

    /// Replaces a captured milestone's photo in place — used by the milestone detail screen's
    /// "change photo" action. Same persistence path as a fresh capture.
    func updatePhoto(_ photo: UIImage, forMilestoneId milestoneId: String, inListId listId: String) {
        capture(photo: photo, forMilestoneId: milestoneId, inListId: listId)
    }

    private func persistCustomLists() {
        let metas = lists.filter { !$0.isStandard }.map { MilestoneRemoteStore.RemoteListMeta(id: $0.id, name: $0.name) }
        MilestoneRemoteStore.saveCustomLists(metas)
    }
}
