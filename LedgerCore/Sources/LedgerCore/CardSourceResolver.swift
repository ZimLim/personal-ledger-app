import Foundation

/// Resolves the Apple Pay card name supplied by the Shortcuts trigger into a
/// preferred `source` label (RFC §5.3). A user-editable mapping wins; otherwise
/// unmapped cards fall back to `"Apple Pay – <card name>"`.
public enum CardSourceResolver {

    public static let genericFallback = "Apple Pay"
    /// Prefix of the label an unmapped card gets: `"Apple Pay – <card name>"`.
    public static let fallbackPrefix = "Apple Pay – "

    /// - Parameters:
    ///   - card: the card display name from the Transaction trigger (may be nil/empty).
    ///   - mapping: user-configured `cardName -> source` overrides.
    public static func source(forCard card: String?, mapping: [String: String] = [:]) -> String {
        let name = (card ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return genericFallback }
        if let mapped = mapping[name]?.trimmingCharacters(in: .whitespacesAndNewlines), !mapped.isEmpty {
            return mapped
        }
        return fallbackPrefix + name
    }

    /// Card names the automation has logged under the fallback label and that
    /// still have no mapping, most recently used first — offered as suggestions
    /// on the card mapping screen so the exact name never has to be typed.
    public static func unmappedCards(
        in transactions: [TransactionData],
        mapping: [String: String] = [:]
    ) -> [String] {
        // A mapped label may itself start with the prefix; that is a chosen
        // source, not a card name.
        let mappedSources = Set(mapping.values)
        var seen = Set<String>()
        return transactions
            .filter {
                $0.entryMethod == .automation
                    && $0.source.hasPrefix(fallbackPrefix)
                    && !mappedSources.contains($0.source)
            }
            .sorted { $0.date > $1.date }
            .map { String($0.source.dropFirst(fallbackPrefix.count)) }
            .filter { mapping[$0] == nil && seen.insert($0).inserted }
    }
}
