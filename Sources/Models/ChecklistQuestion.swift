import Foundation

// MARK: - Checklist question
//
// One line of the before-you-buy list. Five ship with the app; the user may remove any of them
// and add their own, so a question is a RECORD, not a constant (finished-product law 2).
//
// Two things make a question answerable in a shop, one-handed:
//
//   · **Its two answers are its own words**, not a generic Yes/No. "I know" / "No idea" is a
//     question someone can answer without re-reading it; "Yes" / "No" to "Where exactly will it
//     live?" is a puzzle.
//   · **It declares which side points at waiting.** The lean cannot be inferred from the words:
//     "Do I already own one?" leans wait on YES, "Do I have space for it?" leans wait on NO.
//     A checklist that guesses this is wrong half the time, which is worse than not counting.

struct ChecklistQuestion: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    /// Asked in full while the row is unanswered.
    var text: String
    /// Stands in for the question once it is answered and the row collapses.
    var shortLabel: String
    var leftAnswer: String
    var rightAnswer: String
    /// True when the LEFT button is the one that points at waiting.
    var waitIsLeft: Bool
    /// How this answer reads in the verdict's reason line ("no idea where it lives"). Custom
    /// questions have none — they still count, they just do not get to phrase the summary.
    var waitReason: String?
    var isStock: Bool

    init(
        id: UUID = UUID(),
        text: String,
        shortLabel: String,
        leftAnswer: String,
        rightAnswer: String,
        waitIsLeft: Bool,
        waitReason: String? = nil,
        isStock: Bool = false
    ) {
        self.id = id
        self.text = text
        self.shortLabel = shortLabel
        self.leftAnswer = leftAnswer
        self.rightAnswer = rightAnswer
        self.waitIsLeft = waitIsLeft
        self.waitReason = waitReason
        self.isStock = isStock
    }

    /// The label of whichever side points at waiting — used to speak the lean aloud.
    var waitAnswer: String { waitIsLeft ? leftAnswer : rightAnswer }

    /// Does choosing the left button point at waiting?
    func leansToWaiting(pickedLeft: Bool) -> Bool { pickedLeft == waitIsLeft }

    func answerLabel(pickedLeft: Bool) -> String { pickedLeft ? leftAnswer : rightAnswer }

    // MARK: - The five that ship

    static let stock: [ChecklistQuestion] = [
        ChecklistQuestion(
            text: "Do I already own something that does this?",
            shortLabel: "Already own",
            leftAnswer: "Yes",
            rightAnswer: "No",
            waitIsLeft: true,
            waitReason: "already own one",
            isStock: true
        ),
        ChecklistQuestion(
            text: "Will I remember wanting it in a month?",
            shortLabel: "Remember in a month",
            leftAnswer: "Yes",
            rightAnswer: "No",
            waitIsLeft: false,
            waitReason: "won't remember it",
            isStock: true
        ),
        ChecklistQuestion(
            text: "Where exactly will it live?",
            shortLabel: "Where it lives",
            leftAnswer: "I know",
            rightAnswer: "No idea",
            waitIsLeft: false,
            waitReason: "no idea where it lives",
            isStock: true
        ),
        ChecklistQuestion(
            text: "Would I still buy it after 24 hours?",
            shortLabel: "After 24 hours",
            leftAnswer: "Yes",
            rightAnswer: "Unsure",
            waitIsLeft: false,
            waitReason: "unsure after 24 hours",
            isStock: true
        ),
        ChecklistQuestion(
            text: "Am I buying the thing, or the feeling?",
            shortLabel: "Thing or feeling",
            leftAnswer: "The thing",
            rightAnswer: "The feeling",
            waitIsLeft: false,
            waitReason: "buying the feeling",
            isStock: true
        ),
    ]

    /// A question the user typed. Their words are kept verbatim; only the short label is derived,
    /// and it is derived by TRUNCATION rather than by rewording — the app does not paraphrase a
    /// person's own question back at them.
    static func custom(text: String, waitIsLeft: Bool) -> ChecklistQuestion {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return ChecklistQuestion(
            text: trimmed,
            shortLabel: Self.shorten(trimmed),
            leftAnswer: "Yes",
            rightAnswer: "No",
            waitIsLeft: waitIsLeft,
            waitReason: nil,
            isStock: false
        )
    }

    static func shorten(_ text: String) -> String {
        let stripped = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "?."))
        guard stripped.count > 26 else { return stripped }
        let words = stripped.split(separator: " ")
        var out = ""
        for word in words {
            if out.count + word.count + 1 > 26 { break }
            out += out.isEmpty ? String(word) : " \(word)"
        }
        return out.isEmpty ? String(stripped.prefix(26)) : out
    }
}

// MARK: - The reading
//
// The verdict slot renders in EVERY state (M-05 fixed slots), so its text is a pure function of
// the answers so far — never an `if` that removes the view. Kept out of the screen deliberately:
// the sentence the app says about someone's own judgement is worth a test.

struct ChecklistReading: Equatable {
    let total: Int
    let answered: Int
    let waiting: Int
    let reasons: [String]

    var isComplete: Bool { total > 0 && answered == total }
    /// The hold action wakes as soon as anything leans toward waiting.
    var anythingLeansToWaiting: Bool { waiting > 0 }

    init(questions: [ChecklistQuestion], answers: [UUID: Bool]) {
        total = questions.count
        let answeredQuestions = questions.compactMap { question -> (ChecklistQuestion, Bool)? in
            guard let pickedLeft = answers[question.id] else { return nil }
            return (question, pickedLeft)
        }
        answered = answeredQuestions.count
        let leaning = answeredQuestions.filter { $0.0.leansToWaiting(pickedLeft: $0.1) }
        waiting = leaning.count
        reasons = leaning.compactMap(\.0.waitReason)
    }

    /// One line, always present.
    var headline: String {
        guard total > 0 else { return "No questions left — add one, or bring the five back." }
        guard answered > 0 else { return "Answer what you can — a partial read still counts." }

        if isComplete {
            if waiting == 0 { return "Nothing here points to waiting." }
            return "\(waiting) of \(total) point to waiting."
        }
        return "\(answered) of \(total) answered — \(leanClause)."
    }

    /// The reasons under the headline, at most three: a list long enough to argue with is a list
    /// nobody reads mid-craving.
    var reasonLine: String? {
        guard !reasons.isEmpty else { return nil }
        let shown = reasons.prefix(3).joined(separator: "; ")
        return shown.prefix(1).uppercased() + shown.dropFirst() + "."
    }

    private var leanClause: String {
        switch (answered, waiting) {
        case let (a, w) where w == 0:
            return a == 1 ? "it leans toward buying" : "none lean toward waiting"
        case let (a, w) where a == w:
            switch a {
            case 1: return "it leans toward waiting"
            case 2: return "both lean toward waiting"
            default: return "all lean toward waiting"
            }
        case let (_, w):
            return w == 1 ? "one leans toward waiting" : "\(w) lean toward waiting"
        }
    }

    /// Spoken form — VoiceOver gets the same two sentences as the screen, in one utterance.
    var spoken: String {
        [headline, reasonLine].compactMap { $0 }.joined(separator: " ")
    }
}
