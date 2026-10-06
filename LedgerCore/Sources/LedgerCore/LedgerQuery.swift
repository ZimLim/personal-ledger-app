import Foundation

/// Sort options for the ledger list (improvement #1).
public enum LedgerSort: String, CaseIterable, Sendable {
    case dateNewest
    case dateOldest
    case amountHighest
    case amountLowest

    public static let `default`: LedgerSort = .dateNewest

    public var label: String {
        switch self {
        case .dateNewest: return "Newest first"
        case .dateOldest: return "Oldest first"
        case .amountHighest: return "Amount: high to low"
        case .amountLowest: return "Amount: low to high"
        }
    }
}

/// Pure filtering + sorting for the ledger list (improvement #1). Operates on the
/// domain value type so the view can reuse it and it stays unit-tested.
public enum LedgerQuery {

    /// Distinct payment methods (`source`) present, sorted alphabetically — the
    /// options for the "filter by payment method" menu.
    public static func distinctSources(in transactions: [TransactionData]) -> [String] {
        Set(transactions.map(\.source)).sorted()
    }

    /// Keep only transactions whose source matches. `nil`/empty → no filtering.
    public static func filter(source: String?, in transactions: [TransactionData]) -> [TransactionData] {
        guard let source, !source.isEmpty else { return transactions }
        return transactions.filter { $0.source == source }
    }

    public static func sorted(_ transactions: [TransactionData], by sort: LedgerSort) -> [TransactionData] {
        switch sort {
        case .dateNewest:    return transactions.sorted { $0.date > $1.date }
        case .dateOldest:    return transactions.sorted { $0.date < $1.date }
        case .amountHighest: return transactions.sorted { $0.effectiveAmount > $1.effectiveAmount }
        case .amountLowest:  return transactions.sorted { $0.effectiveAmount < $1.effectiveAmount }
        }
    }

    /// Filter by payment method, then sort.
    public static func visible(
        _ transactions: [TransactionData],
        source: String?,
        sort: LedgerSort
    ) -> [TransactionData] {
        sorted(filter(source: source, in: transactions), by: sort)
    }
}
