import Foundation

/// Suggests a category for a merchant from what the user last chose there.
/// `Other` rows are skipped because `Other` means unsorted and should not teach
/// the lookup.
public enum CategorySuggester {

    /// - Parameter newestFirst: the transaction history, newest first by `date`.
    /// - Returns: the category of the newest non-`Other` entry whose merchant
    ///   matches (trimmed, case-insensitive), or `nil` if there is none.
    public static func suggest(merchant: String, in newestFirst: [TransactionData]) -> String? {
        let key = DuplicateGuard.normalizedMerchant(merchant)
        guard !key.isEmpty else { return nil }
        return newestFirst.first {
            $0.category != SpendingCategory.other.rawValue
                && DuplicateGuard.normalizedMerchant($0.merchant) == key
        }?.category
    }
}
