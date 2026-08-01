import Foundation

/// A (year, month) bucket — the identity of a ledger (RFC §3.2). Ledgers are not
/// stored; they are derived by grouping transactions on this value.
public struct YearMonth: Hashable, Comparable, Sendable {
    public let year: Int
    /// 1...12
    public let month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    /// The bucket a date falls into, using the given calendar/timezone
    /// (defaults to the device's — RFC §8 "Timezone").
    public init(date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month], from: date)
        self.year = c.year ?? 1
        self.month = c.month ?? 1
    }

    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    /// Localized standalone month name, e.g. "August". Month names are a locale
    /// concern (not a calendar one), so this takes a `Locale`.
    public func monthName(locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        let symbols = formatter.standaloneMonthSymbols ?? []
        guard month >= 1, month <= symbols.count else { return "\(month)" }
        return symbols[month - 1]
    }

    /// e.g. "August 2026" — the ledger header (RFC §FR-1).
    public func displayName(locale: Locale = .current) -> String {
        "\(monthName(locale: locale)) \(year)"
    }
}
