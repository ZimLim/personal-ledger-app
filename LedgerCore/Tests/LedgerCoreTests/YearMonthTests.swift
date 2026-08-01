import Testing
import Foundation
@testable import LedgerCore

@Suite struct YearMonthTests {

    @Test func derivesYearAndMonthFromDate() {
        let ym = YearMonth(date: day(2026, 8, 15), calendar: .utc)
        #expect(ym.year == 2026)
        #expect(ym.month == 8)
    }

    @Test func ordersChronologically() {
        #expect(YearMonth(year: 2025, month: 12) < YearMonth(year: 2026, month: 1))
        #expect(YearMonth(year: 2026, month: 7) < YearMonth(year: 2026, month: 8))
    }

    @Test func displayNameIsMonthAndYear() {
        #expect(YearMonth(year: 2026, month: 8).displayName(locale: enUS) == "August 2026")
    }

    @Test func equatableByComponents() {
        #expect(YearMonth(year: 2026, month: 8) == YearMonth(date: day(2026, 8, 1), calendar: .utc))
    }
}
