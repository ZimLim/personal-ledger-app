import Testing
import Foundation
@testable import LedgerCore

@Suite struct CSVExporterTests {

    @Test func headerMatchesSpec() {
        #expect(CSVExporter.header == "date,amount,currency,type,category,source,merchant,entry_method")
    }

    @Test func expenseRowFormatsAllColumns() {
        let csv = CSVExporter.export([
            tx(amount: "23.50", source: "Cash", date: day(2026, 8, 1),
               merchant: "Village Grocer", kind: .expense, category: "Groceries"),
        ], calendar: .utc)

        let rows = csv.split(separator: "\n").map(String.init)
        #expect(rows.count == 2)
        #expect(rows[1] == "2026-08-01,23.50,MYR,expense,Groceries,Cash,Village Grocer,manual")
    }

    @Test func refundRowCarriesSignedAmountAndType() {
        let csv = CSVExporter.export([
            tx(amount: "23.50", source: "Cash", date: day(2026, 8, 2),
               merchant: "Village Grocer", kind: .refund, category: "Groceries"),
        ], calendar: .utc)
        #expect(csv.contains("2026-08-02,-23.50,MYR,refund,Groceries,Cash,Village Grocer,manual"))
    }

    @Test func emptyMerchantLeavesBlankField() {
        let csv = CSVExporter.export([
            tx(amount: "8.00", source: "Cash", date: day(2026, 8, 1),
               merchant: nil, kind: .expense, category: "Food"),
        ], calendar: .utc)
        #expect(csv.contains("2026-08-01,8.00,MYR,expense,Food,Cash,,manual"))
    }

    @Test func quotesFieldsContainingComma() {
        #expect(CSVExporter.escape("Cash, big") == "\"Cash, big\"")
    }

    @Test func escapesEmbeddedQuotesByDoubling() {
        #expect(CSVExporter.escape("7\" sub") == "\"7\"\" sub\"")
    }

    @Test func leavesPlainFieldsUnquoted() {
        #expect(CSVExporter.escape("Village Grocer") == "Village Grocer")
    }

    @Test func monthFilenameIsZeroPadded() {
        #expect(CSVExporter.monthFilename(for: YearMonth(year: 2026, month: 8)) == "spending-2026-08.csv")
    }

    @Test func allFilenameUsesCompactDate() {
        #expect(CSVExporter.allFilename(on: day(2026, 8, 2), calendar: .utc) == "spending-all-20260802.csv")
    }

    @Test func sortForExportIsAscendingByDate() {
        let sorted = CSVExporter.sortedForExport([
            tx(amount: "1.00", date: day(2026, 8, 20)),
            tx(amount: "2.00", date: day(2026, 8, 1)),
            tx(amount: "3.00", date: day(2026, 8, 10)),
        ])
        #expect(sorted.map(\.date) == [day(2026, 8, 1), day(2026, 8, 10), day(2026, 8, 20)])
    }
}
