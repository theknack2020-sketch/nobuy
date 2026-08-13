import Foundation
import Observation

// MARK: - Checklist store
//
// The user's question list, kept the same way its two siblings are kept
// (`WaitingListManager`, `AchievementManager`): one Codable blob under one key. A SwiftData
// entity would buy ordering and undo we already have here for a seven-row list, and would cost
// a schema migration in a release that is already carrying three new surfaces.
//
// Removal is a TWO-STEP: the row leaves the list immediately and the removed question is held
// for five seconds so the toast's Undo can put it back at its own index. A delete that cannot
// be taken back is the defect this design exists to avoid — nothing here is ever permanent on
// the first tap.

@Observable
@MainActor
final class ChecklistStore {
    static let shared = ChecklistStore()

    private let storageKey = "checklistQuestions"

    private(set) var questions: [ChecklistQuestion] = []

    /// The last removal, waiting for its undo window to close.
    private(set) var pendingRemoval: PendingRemoval?

    struct PendingRemoval: Equatable {
        let question: ChecklistQuestion
        let index: Int
    }

    private var undoTask: Task<Void, Never>?

    init() {
        load()
    }

    // MARK: - Editing

    func add(text: String, waitIsLeft: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        questions.append(.custom(text: trimmed, waitIsLeft: waitIsLeft))
        save()
    }

    func remove(_ question: ChecklistQuestion) {
        guard let index = questions.firstIndex(of: question) else { return }
        questions.remove(at: index)
        save()
        offerUndo(PendingRemoval(question: question, index: index))
    }

    func move(from source: IndexSet, to destination: Int) {
        questions.move(fromOffsets: source, toOffset: destination)
        save()
    }

    /// Puts the last removed question back where it was. Its index may no longer exist — the
    /// user can add or remove while the toast is up — so the position is clamped rather than
    /// trusted.
    func undoRemoval() {
        guard let pending = pendingRemoval else { return }
        let index = min(max(pending.index, 0), questions.count)
        questions.insert(pending.question, at: index)
        save()
        clearPendingRemoval()
    }

    func clearPendingRemoval() {
        undoTask?.cancel()
        undoTask = nil
        pendingRemoval = nil
    }

    /// Restores the five that ship. Their previous ids are not reused, so any answer held
    /// against an old id is simply dropped rather than re-attached to a different question.
    func restoreStockQuestions() {
        let existingStockText = Set(questions.filter(\.isStock).map(\.text))
        let missing = ChecklistQuestion.stock.filter { !existingStockText.contains($0.text) }
        guard !missing.isEmpty else { return }
        questions.insert(contentsOf: missing, at: 0)
        save()
    }

    var isMissingStockQuestions: Bool {
        let present = Set(questions.filter(\.isStock).map(\.text))
        return ChecklistQuestion.stock.contains { !present.contains($0.text) }
    }

    // MARK: - Undo window

    private func offerUndo(_ removal: PendingRemoval) {
        undoTask?.cancel()
        pendingRemoval = removal
        undoTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            self?.pendingRemoval = nil
        }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            questions = ChecklistQuestion.stock
            return
        }
        do {
            questions = try JSONDecoder().decode([ChecklistQuestion].self, from: data)
        } catch {
            // A list that cannot be read is not a list that should be silently replaced: the
            // stock five come back so the screen still works, and the failure is logged rather
            // than swallowed.
            AppLogger.data.error("Could not read the checklist: \(error.localizedDescription)")
            questions = ChecklistQuestion.stock
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(questions)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            AppLogger.data.error("Could not save the checklist: \(error.localizedDescription)")
        }
    }

    #if DEBUG
        /// Test seam: a store with an explicit list and no persistence.
        static func inMemory(_ questions: [ChecklistQuestion]) -> ChecklistStore {
            let store = ChecklistStore(questions: questions)
            return store
        }

        private init(questions: [ChecklistQuestion]) {
            self.questions = questions
        }
    #endif
}
