import Foundation

/// Resolves the Apple Pay card name supplied by the Shortcuts trigger into a
/// preferred `source` label (RFC §5.3). A user-editable mapping wins; otherwise
/// unmapped cards fall back to `"Apple Pay – <card name>"`.
public enum CardSourceResolver {

    public static let genericFallback = "Apple Pay"

    /// - Parameters:
    ///   - card: the card display name from the Transaction trigger (may be nil/empty).
    ///   - mapping: user-configured `cardName -> source` overrides.
    public static func source(forCard card: String?, mapping: [String: String] = [:]) -> String {
        let name = (card ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return genericFallback }
        if let mapped = mapping[name]?.trimmingCharacters(in: .whitespacesAndNewlines), !mapped.isEmpty {
            return mapped
        }
        return "Apple Pay – \(name)"
    }
}
