import Foundation

/// The user-editable `card name → source` overrides (RFC §5.3), kept in
/// `UserDefaults`. `LedgerCore.CardSourceResolver` applies them; this type only
/// stores them. Each write replaces the stored dictionary with a new one.
struct CardMappingStore {
    static let defaultsKey = "cardSourceMapping"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Stored preferences are untrusted: anything but a string-to-string
    /// dictionary reads as no mappings.
    var mapping: [String: String] {
        defaults.dictionary(forKey: Self.defaultsKey) as? [String: String] ?? [:]
    }

    /// Maps `card` to `source`, both trimmed. Returns `false` and stores nothing
    /// if either is blank.
    @discardableResult
    func setSource(_ source: String, forCard card: String) -> Bool {
        let card = card.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !card.isEmpty, !source.isEmpty else { return false }
        defaults.set(mapping.merging([card: source]) { _, new in new }, forKey: Self.defaultsKey)
        return true
    }

    func removeCard(_ card: String) {
        defaults.set(mapping.filter { $0.key != card }, forKey: Self.defaultsKey)
    }
}
