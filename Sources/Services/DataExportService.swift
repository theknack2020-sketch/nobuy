import Foundation
import os
import SwiftData

enum DataExportError: LocalizedError {
    case noData
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noData:
            L10n.exportEmpty
        case .writeFailed:
            L10n.errorExportMessage
        }
    }

    var userMessage: String {
        switch self {
        case .noData:
            L10n.exportEmpty
        case .writeFailed:
            L10n.errorExportMessage
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
            let fields = [
                record.date.formatted(date: .abbreviated, time: .omitted),
                record.didSpend ? "Yes" : "No",
                record.isMandatoryOnly ? "Yes" : "No",
                record.isFrozen ? "Yes" : "No",
                record.amount.map { String(format: "%.2f", $0) } ?? "",
                record.note ?? "",
            ]
            return fields.map(csvEscaped).joined(separator: ",")
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

    /// RFC-4180 field escaping: wrap in double quotes and double embedded
    /// quotes, so commas, quotes and newlines in notes stay legal CSV.
    static func csvEscaped(_ field: String) -> String {
        "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
