import Foundation

/// One day of a month and what was spent on it (plan Phase 6).
public struct DayTotal: Equatable, Sendable, Identifiable {
    /// 1...31
    public let day: Int
    /// Sum of the day's effective amounts: zero when nothing is logged, negative
    /// on a refund-only day.
    public let total: Decimal

    public var id: Int { day }

    public init(day: Int, total: Decimal) {
        self.day = day
        self.total = total
    }
}

/// A month laid out for a 7-column calendar grid: every day of the month with
/// its total, plus how many cells to leave empty before day 1 (plan Phase 6).
public struct MonthCalendar: Equatable, Sendable {
    private static let daysPerWeek = 7

    public let month: YearMonth
    /// Empty cells before day 1 so it lands under its weekday. Follows the
    /// calendar's `firstWeekday`.
    public let leadingBlanks: Int
    /// One entry per day of the month, ascending. A day without transactions —
    /// including one still to come — totals zero.
    public let days: [DayTotal]

    public init(
        month: YearMonth,
        transactions: [TransactionData],
        calendar: Calendar = .current
    ) {
        self.month = month
        let firstDay = DateComponents(year: month.year, month: month.month, day: 1)
        guard let firstOfMonth = calendar.date(from: firstDay),
              let dayRange = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            self.leadingBlanks = 0
            self.days = []
            return
        }

        let inMonth = LedgerGrouping.transactions(in: month, from: transactions, calendar: calendar)
        let totalsByDay = Dictionary(grouping: inMonth) { calendar.component(.day, from: $0.date) }
            .mapValues(LedgerTotals.total(of:))
        let weekday = calendar.component(.weekday, from: firstOfMonth)

        self.leadingBlanks = (weekday - calendar.firstWeekday + Self.daysPerWeek) % Self.daysPerWeek
        self.days = dayRange.map { DayTotal(day: $0, total: totalsByDay[$0] ?? .zero) }
    }

    /// Short weekday names ("Sun", "Mon", …) in grid order, starting from the
    /// calendar's `firstWeekday`.
    public static func weekdaySymbols(calendar: Calendar = .current) -> [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        guard symbols.indices.contains(start) else { return symbols }
        return Array(symbols[start...] + symbols[..<start])
    }
}
