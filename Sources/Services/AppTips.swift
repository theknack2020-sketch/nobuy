import TipKit

struct StreakTip: Tip {
    var title: Text { Text("Build Your Streak") }
    var message: Text? { Text("Mark each no-spend day to grow your streak. Consistency is key!") }
    var image: Image? { Image(systemName: "flame.fill") }
}

struct ImpulseChecklistTip: Tip {
    var title: Text { Text("Feeling the Urge?") }
    var message: Text? { Text("Use the impulse checklist before making a purchase. It helps you pause and decide.") }
    var image: Image? { Image(systemName: "checklist") }

    @Parameter
    static var hasLoggedDay: Bool = false

    var rules: [Rule] {
        #Rule(Self.$hasLoggedDay) { $0 == true }
    }
}

struct WaitingListTip: Tip {
    var title: Text { Text("Add It to Your Waiting List") }
    var message: Text? { Text("Most impulse purchases fade within 24 hours. Save it here and revisit later.") }
    var image: Image? { Image(systemName: "clock.badge.questionmark") }

    @Parameter
    static var hasUsedChecklist: Bool = false

    var rules: [Rule] {
        #Rule(Self.$hasUsedChecklist) { $0 == true }
    }
}
