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
        ("Kira", "house"),
        ("Fatura", "bolt"),
        ("Ulaşım", "bus"),
        ("Market (temel gıda)", "cart"),
    ]
}
