import Foundation

struct WaitingItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var estimatedCost: Double?
    var dateAdded: Date
    var reminderDate: Date
    var isResolved: Bool = false
    var didBuy: Bool? = nil  // nil = not yet decided, true = bought, false = decided not to

    init(name: String, estimatedCost: Double? = nil, reminderHours: Int = 24) {
        self.id = UUID()
        self.name = name
        self.estimatedCost = estimatedCost
        self.dateAdded = .now
        self.reminderDate = Calendar.current.date(byAdding: .hour, value: reminderHours, to: .now) ?? .now
    }
}
