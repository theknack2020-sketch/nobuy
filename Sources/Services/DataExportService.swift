import Foundation
import SwiftData
import os

enum DataExportError: LocalizedError {
    case noData
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noData:
            return L10n.exportEmpty
        case .writeFailed:
            return L10n.errorExportMessage
        }
    }

    var userMessage: String {
        switch self {
        case .noData:
            return L10n.exportEmpty
        case .writeFailed:
            return L10n.errorExportMessage
        }
    }
}

enum DataExportService {
    /// Exports all DayRecord entries to a CSV file matching the full schema.
    /// Returns the temporary file URL on success.
    /// Throws DataExportError on failure with user-friendly messages.
    static func exportCSV(records: [DayRecord]) throws -> URL {
        guard !records.isEmpty else {
            throw DataExportError.noData
        }

        let header = "Date,Spent,Essential Only,Freeze,Amount,Note\n"
        let rows = records.sorted(by: { $0.date < $1.date }).map { record in
            let dateStr = record.date.formatted(date: .abbreviated, time: .omitted)
            let spent = record.didSpend ? "Yes" : "No"
            let mandatory = record.isMandatoryOnly ? "Yes" : "No"
            let frozen = record.isFrozen ? "Yes" : "No"
            let amount = record.amount.map { String(format: "%.2f", $0) } ?? ""
            let note = (record.note ?? "").replacingOccurrences(of: ",", with: ";")
            return "\(dateStr),\(spent),\(mandatory),\(frozen),\(amount),\(note)"
        }.joined(separator: "\n")

        let csv = header + rows

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("NoBuy-Export-\(dateFormatter.string(from: .now)).csv")

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            AppLogger.data.info("CSV export succeeded: \(records.count) records")
            return tempURL
        } catch {
            AppLogger.data.error("CSV export failed: \(error.localizedDescription)")
            throw DataExportError.writeFailed(error)
        }
    }
}
