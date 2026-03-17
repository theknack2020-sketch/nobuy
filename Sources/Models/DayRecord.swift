import Foundation
import SwiftData

@Model
final class DayRecord {
    var date: Date
    var didSpend: Bool
    var isMandatoryOnly: Bool // true = harcama yaptı ama sadece zorunlu (kira/fatura)
    var note: String?
    var createdAt: Date

    init(
        date: Date = .now,
        didSpend: Bool = false,
        isMandatoryOnly: Bool = false,
        note: String? = nil
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.didSpend = didSpend
        self.isMandatoryOnly = isMandatoryOnly
        self.note = note
        self.createdAt = .now
    }

    /// A no-spend day: either didn't spend at all, or only mandatory spending
    var isNoBuyDay: Bool {
        !didSpend || isMandatoryOnly
    }

    /// Normalized date for comparison (start of day)
    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }
}
