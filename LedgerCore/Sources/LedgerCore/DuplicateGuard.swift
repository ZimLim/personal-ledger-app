import Foundation

/// Idempotency guard for automation logging (RFC §5.2): a Shortcuts "Transaction"
/// trigger can fire twice for one purchase. An incoming automation entry is a
/// duplicate if an existing *automation* entry matches on amount + merchant and
/// falls within a small time window.
public enum DuplicateGuard {

    /// Default matching window (± seconds) around the candidate's date.
    public static let defaultWindow: TimeInterval = 60

    public static func isDuplicate(
        of candidate: TransactionData,
        in existing: [TransactionData],
        window: TimeInterval = defaultWindow
    ) -> Bool {
        existing.contains { other in
            other.id != candidate.id
                && other.entryMethod == .automation
                && candidate.entryMethod == .automation
                && other.amount == candidate.amount
                && normalizedMerchant(other.merchant) == normalizedMerchant(candidate.merchant)
                && abs(other.date.timeIntervalSince(candidate.date)) <= window
        }
    }

    /// Merchant comparison ignores surrounding whitespace and case; a missing
    /// merchant is treated as empty (automation entries may omit it — RFC §8).
    private static func normalizedMerchant(_ merchant: String?) -> String {
        (merchant ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
