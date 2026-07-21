import Foundation
import SwiftData

@Model
final class DayRecord {
    var date: Date
    var didSpend: Bool
    var isMandatoryOnly: Bool // true = spent, but only on essentials (rent/bills)
    var isFrozen: Bool // true = a streak freeze was used; the streak did not break
    var note: String?
    var amount: Double?
    var createdAt: Date

    init(
        date: Date = .now,
        didSpend: Bool = false,
        isMandatoryOnly: Bool = false,
        isFrozen: Bool = false,
        note: String? = nil,
        amount: Double? = nil
    ) {
        self.date = Self.dayAnchor(for: date)
        self.didSpend = didSpend
        self.isMandatoryOnly = isMandatoryOnly
        self.isFrozen = isFrozen
        self.note = note
        self.amount = amount
        self.createdAt = .now
    }

    /// Anchor a record at LOCAL NOON of its calendar day, not midnight.
    /// Day identity is re-derived on read via `startOfDay` in the *current*
    /// timezone; a midnight instant flips to the previous/next date after any
    /// timezone change, silently shifting logged days and breaking streaks.
    /// Noon survives shifts of up to ±12 hours in either direction.
    static func dayAnchor(for date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .hour, value: 12, to: startOfDay) ?? startOfDay
    }

    /// A no-spend day: either didn't spend at all, only mandatory spending, or frozen (streak preserved)
    var isNoBuyDay: Bool {
        isFrozen || !didSpend || isMandatoryOnly
    }

    /// Normalized date for comparison (start of day)
    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }
}
