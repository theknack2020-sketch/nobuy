import Foundation
import Testing
@testable import NoBuy

/// The checklist says one sentence about a person's own judgement and then offers to hold their
/// money for a day. Both halves are worth pinning:
///
///   · **The lean is DECLARED, never inferred.** "Do I already own one?" points at waiting on
///     YES; "Do I have space for it?" points at waiting on NO. Any code that derives the lean
///     from the answer word alone is wrong for half the questions people actually write, and
///     these tests fail rather than let that ship.
///   · **A removal is reversible.** The undo has to put the question back where it was, even
///     after the list has changed underneath it.
@Suite("Checklist reading")
struct ChecklistReadingTests {
    private let stock = ChecklistQuestion.stock

    private func answers(_ pairs: [(Int, Bool)]) -> [UUID: Bool] {
        var out: [UUID: Bool] = [:]
        for (index, pickedLeft) in pairs { out[stock[index].id] = pickedLeft }
        return out
    }

    @Test("Nothing answered still renders a line — the slot is fixed")
    func idleSlotSpeaks() {
        let reading = ChecklistReading(questions: stock, answers: [:])
        #expect(reading.answered == 0)
        #expect(reading.total == 5)
        #expect(reading.headline == "Answer what you can — a partial read still counts.")
        #expect(reading.reasonLine == nil)
        #expect(reading.anythingLeansToWaiting == false)
    }

    @Test("The lean follows the question's own declaration, not the word 'yes'")
    func leanIsDeclaredPerQuestion() {
        // Q0 "Do I already own something that does this?" — YES points at waiting.
        let owned = ChecklistReading(questions: stock, answers: answers([(0, true)]))
        #expect(owned.waiting == 1)

        // Q1 "Will I remember wanting it in a month?" — YES points at buying.
        let remembered = ChecklistReading(questions: stock, answers: answers([(1, true)]))
        #expect(remembered.waiting == 0)
    }

    @Test("A partial read counts and names how many lean")
    func partialReadCounts() {
        let reading = ChecklistReading(questions: stock, answers: answers([(0, true), (1, true)]))
        #expect(reading.answered == 2)
        #expect(reading.waiting == 1)
        #expect(reading.headline == "2 of 5 answered — one leans toward waiting.")
        #expect(reading.anythingLeansToWaiting)
    }

    @Test("Two answers both leaning are spoken as 'both'")
    func bothLean() {
        let reading = ChecklistReading(questions: stock, answers: answers([(0, true), (2, false)]))
        #expect(reading.waiting == 2)
        #expect(reading.headline == "2 of 5 answered — both lean toward waiting.")
    }

    @Test("A complete read states the count and its reasons")
    func completeReadNamesReasons() {
        let reading = ChecklistReading(
            questions: stock,
            answers: answers([(0, true), (1, true), (2, false), (3, false), (4, false)])
        )
        #expect(reading.isComplete)
        #expect(reading.waiting == 4)
        #expect(reading.headline == "4 of 5 point to waiting.")
        // At most three reasons — a list long enough to argue with is a list nobody reads.
        #expect(reading.reasonLine?.hasSuffix(".") == true)
        #expect(reading.reasons.count == 4)
        let shown = reading.reasonLine ?? ""
        #expect(shown.components(separatedBy: ";").count == 3)
        #expect(shown.hasPrefix("Already own one"))
    }

    @Test("A complete read that leans nowhere says so plainly")
    func completeReadWithNoLean() {
        let reading = ChecklistReading(
            questions: stock,
            answers: answers([(0, false), (1, true), (2, true), (3, true), (4, true)])
        )
        #expect(reading.waiting == 0)
        #expect(reading.headline == "Nothing here points to waiting.")
        #expect(reading.anythingLeansToWaiting == false)
    }

    @Test("An emptied list asks for a question rather than dividing by nothing")
    func emptyListIsNotACrash() {
        let reading = ChecklistReading(questions: [], answers: [:])
        #expect(reading.total == 0)
        #expect(reading.headline == "No questions left — add one, or bring the five back.")
    }

    @Test("A custom question counts toward the lean but does not phrase the summary")
    func customQuestionCountsWithoutAReason() {
        let mine = ChecklistQuestion.custom(text: "Do I have space in the flat?", waitIsLeft: false)
        let reading = ChecklistReading(questions: [mine], answers: [mine.id: false])
        #expect(reading.waiting == 1)
        #expect(reading.headline == "1 of 1 point to waiting.")
        #expect(reading.reasonLine == nil)
    }

    @Test("A typed question keeps its own words and derives only its short label")
    func customQuestionKeepsItsWords() {
        let text = "  Would I buy this at full price, honestly?  "
        let mine = ChecklistQuestion.custom(text: text, waitIsLeft: true)
        #expect(mine.text == "Would I buy this at full price, honestly?")
        #expect(mine.shortLabel.count <= 26)
        #expect(mine.text.hasPrefix(mine.shortLabel))
        #expect(mine.isStock == false)
        #expect(mine.waitAnswer == "Yes")
    }
}

@Suite("Checklist store")
@MainActor
struct ChecklistStoreTests {
    @Test("Undo puts a removed question back at its own index")
    func undoRestoresPosition() {
        let store = ChecklistStore.inMemory(ChecklistQuestion.stock)
        let third = store.questions[2]

        store.remove(third)
        #expect(store.questions.count == 4)
        #expect(store.pendingRemoval?.index == 2)

        store.undoRemoval()
        #expect(store.questions.count == 5)
        #expect(store.questions[2] == third)
        #expect(store.pendingRemoval == nil)
    }

    /// Only ONE removal is ever pending: a second delete replaces the first, and the toast that
    /// is on screen is always about the thing that just left. Anything else would offer to undo
    /// a deletion the user has already stopped thinking about.
    @Test("A second removal takes over the undo slot")
    func onlyTheLatestRemovalIsUndoable() {
        let store = ChecklistStore.inMemory(ChecklistQuestion.stock)
        let last = store.questions[4]
        let first = store.questions[0]

        store.remove(last)
        store.remove(first)
        #expect(store.pendingRemoval?.question == first)

        store.undoRemoval()
        #expect(store.questions.first == first)
        #expect(store.questions.contains(last) == false)
        #expect(store.questions.count == 4)
    }

    @Test("Undo after the list shrank does not trap on a stale index")
    func undoClampsToAValidIndex() {
        // The index is clamped rather than trusted. Nothing in the UI can shrink the list under
        // a pending removal today, so this pins the guard itself: without the clamp an
        // `insert(at: 4)` into a 1-item array is a crash, not a bug report.
        let store = ChecklistStore.inMemory(Array(ChecklistQuestion.stock.prefix(2)))
        let second = store.questions[1]

        store.remove(second)
        store.remove(store.questions[0])
        store.undoRemoval()

        #expect(store.questions.count == 1)
    }

    @Test("Bringing the stock five back adds only what is missing")
    func restoreOnlyFillsGaps() {
        let store = ChecklistStore.inMemory(ChecklistQuestion.stock)
        store.remove(store.questions[0])
        store.clearPendingRemoval()
        #expect(store.isMissingStockQuestions)

        store.restoreStockQuestions()
        #expect(store.questions.count == 5)
        #expect(store.isMissingStockQuestions == false)

        // Running it again is a no-op rather than a duplicate.
        store.restoreStockQuestions()
        #expect(store.questions.count == 5)
    }

    @Test("An empty question is not added")
    func blankQuestionRejected() {
        let store = ChecklistStore.inMemory([])
        store.add(text: "   \n ", waitIsLeft: true)
        #expect(store.questions.isEmpty)
    }
}
