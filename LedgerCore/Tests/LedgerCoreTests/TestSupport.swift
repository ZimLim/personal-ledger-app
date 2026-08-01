import Foundation
@testable import LedgerCore

// Deterministic helpers shared across the suite. A fixed UTC calendar keeps
// date bucketing/formatting stable regardless of where tests run.

extension Calendar {
    static var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
}

let enUS = Locale(identifier: "en_US")

/// A `Decimal` from a canonical string (avoids `Double` imprecision in tests).
func dec(_ s: String) -> Decimal { Decimal(string: s, locale: Money.posix)! }

/// A `Date` at noon UTC on the given day.
func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12, minute: Int = 0) -> Date {
    Calendar.utc.date(
        from: DateComponents(year: y, month: m, day: d, hour: hour, minute: minute)
    )!
}

/// Transaction fixture with sensible defaults.
func tx(
    amount: String = "10.00",
    source: String = "Cash",
    date: Date = day(2026, 8, 1),
    merchant: String? = nil,
    kind: TransactionKind = .expense,
    category: String = "Other",
    entryMethod: EntryMethod = .manual,
    id: UUID = UUID(),
    createdAt: Date = day(2026, 8, 1)
) -> TransactionData {
    TransactionData(
        id: id,
        amount: dec(amount),
        source: source,
        date: date,
        merchant: merchant,
        kind: kind,
        category: category,
        entryMethod: entryMethod,
        createdAt: createdAt
    )
}
