import Foundation

/// Summation over transactions using *effective* (signed) amounts, so refunds
/// subtract and a month can legitimately total negative (RFC §FR-1, §8).
public enum LedgerTotals {
    public static func total(of transactions: [TransactionData]) -> Decimal {
        transactions.reduce(Decimal.zero) { $0 + $1.effectiveAmount }
    }
}
