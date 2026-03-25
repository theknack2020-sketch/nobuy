import Foundation
import SwiftData

@Model
final class MandatoryCategory {
    var name: String
    var icon: String // SF Symbol name
    var createdAt: Date

    init(name: String, icon: String = "building.columns") {
        self.name = name
        self.icon = icon
        self.createdAt = .now
    }

    static let defaults: [(String, String)] = [
        (L10n.categoryRent, "house"),
        (L10n.categoryBills, "bolt"),
        (L10n.categoryTransport, "bus"),
        (L10n.categoryGroceries, "cart"),
    ]
}
