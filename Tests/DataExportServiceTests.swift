import Foundation
import Testing
@testable import NoBuy

@Suite("DataExportService CSV")
struct DataExportServiceTests {
    @Test("Fields with commas, quotes and newlines survive RFC-4180 escaping")
    func csvEscaping() {
        #expect(DataExportService.csvEscaped("plain") == "\"plain\"")
        #expect(DataExportService.csvEscaped("a,b") == "\"a,b\"")
        #expect(DataExportService.csvEscaped("say \"hi\"") == "\"say \"\"hi\"\"\"")
        #expect(DataExportService.csvEscaped("line1\nline2") == "\"line1\nline2\"")
    }

    @Test("Export keeps one logical record per row even with a multiline note")
    @MainActor
    func multilineNoteExport() throws {
        let record = DayRecord(
            date: .now,
            didSpend: true,
            note: "Bought \"shoes\",\nregret it",
            amount: 49.99
        )
        let url = try DataExportService.exportCSV(records: [record])
        let content = try String(contentsOf: url, encoding: .utf8)

        // Header + one escaped record; the embedded newline lives INSIDE
        // quotes, so a strict split on unquoted newlines yields 2 rows.
        #expect(content.hasPrefix("Date,Spent,Essential Only,Freeze,Amount,Note"))
        #expect(content.contains("\"Bought \"\"shoes\"\",\nregret it\""))
    }
}
