import Testing
import Foundation
@testable import LedgerCore

@Suite struct LedgerTotalsTests {

    @Test func sumsEffectiveAmounts() {
        let total = LedgerTotals.total(of: [
            tx(amount: "10.00", kind: .expense),
            tx(amount: "3.00", kind: .refund),
        ])
        #expect(total == dec("7.00"))
    }

    @Test func canBeNegativeInRefundHeavyMonth() {
        let total = LedgerTotals.total(of: [
            tx(amount: "5.00", kind: .expense),
            tx(amount: "20.00", kind: .refund),
        ])
        #expect(total == dec("-15.00"))
    }

    @Test func emptyIsZero() {
        #expect(LedgerTotals.total(of: []) == Decimal.zero)
    }
}

@Suite struct LedgerGroupingTests {

    @Test func groupsByMonthNewestFirst() {
        let months = LedgerGrouping.byMonth([
            tx(date: day(2026, 7, 10)),
            tx(date: day(2026, 8, 5)),
            tx(date: day(2025, 12, 1)),
        ], calendar: .utc)

        #expect(months.map(\.month) == [
            YearMonth(year: 2026, month: 8),
            YearMonth(year: 2026, month: 7),
            YearMonth(year: 2025, month: 12),
        ])
    }

    @Test func transactionsWithinMonthAreNewestDateFirst() {
        let months = LedgerGrouping.byMonth([
            tx(amount: "1.00", date: day(2026, 8, 1)),
            tx(amount: "2.00", date: day(2026, 8, 20)),
            tx(amount: "3.00", date: day(2026, 8, 10)),
        ], calendar: .utc)

        let august = try! #require(months.first)
        #expect(august.transactions.map(\.date) == [day(2026, 8, 20), day(2026, 8, 10), day(2026, 8, 1)])
    }

    @Test func filtersTransactionsForOneMonth() {
        let all = [
            tx(date: day(2026, 8, 5)),
            tx(date: day(2026, 7, 30)),
        ]
        let august = LedgerGrouping.transactions(
            in: YearMonth(year: 2026, month: 8), from: all, calendar: .utc
        )
        #expect(august.count == 1)
        #expect(august.first?.date == day(2026, 8, 5))
    }
}
