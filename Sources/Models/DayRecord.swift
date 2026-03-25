import Foundation
import SwiftData

@Model
final class DayRecord {
    var date: Date
    var didSpend: Bool
    var isMandatoryOnly: Bool // true = harcama yaptı ama sadece zorunlu (kira/fatura)
    var isFrozen: Bool // true = streak freeze kullanıldı, streak kırılmadı
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
        self.date = Calendar.current.startOfDay(for: date)
        self.didSpend = didSpend
        self.isMandatoryOnly = isMandatoryOnly
        self.isFrozen = isFrozen
        self.note = note
        self.amount = amount
        self.createdAt = .now
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
