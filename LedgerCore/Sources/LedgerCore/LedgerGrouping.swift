import Foundation

/// A month's worth of transactions plus its identity — what the ledger view and
/// the sidebar render (RFC §FR-1, §FR-3).
public struct LedgerMonth: Equatable, Sendable {
    public let month: YearMonth
    /// Reverse-chronological (newest first), per the ledger list (RFC §FR-1).
    public let transactions: [TransactionData]

    public init(month: YearMonth, transactions: [TransactionData]) {
        self.month = month
        self.transactions = transactions
    }

    /// Running total = sum of effective amounts; can be negative in refund-heavy
    /// months (RFC §FR-1, §8).
    public var total: Decimal {
        LedgerTotals.total(of: transactions)
    }
}

/// Pure grouping of transactions into month buckets.
public enum LedgerGrouping {

    /// Group transactions by `YearMonth`, newest month first, each month's
    /// transactions sorted newest-date first (RFC §FR-1, §FR-3).
    public static func byMonth(
        _ transactions: [TransactionData],
        calendar: Calendar = .current
    ) -> [LedgerMonth] {
        let buckets = Dictionary(grouping: transactions) {
            YearMonth(date: $0.date, calendar: calendar)
        }
        return buckets
            .map { key, value in
                LedgerMonth(month: key, transactions: value.sorted { $0.date > $1.date })
            }
            .sorted { $0.month > $1.month }
    }

    /// Transactions for one specific month, newest-date first (RFC §FR-1).
    public static func transactions(
        in month: YearMonth,
        from transactions: [TransactionData],
        calendar: Calendar = .current
    ) -> [TransactionData] {
        transactions
            .filter { YearMonth(date: $0.date, calendar: calendar) == month }
            .sorted { $0.date > $1.date }
    }
}
