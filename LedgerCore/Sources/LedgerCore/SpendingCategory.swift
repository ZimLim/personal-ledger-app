import Foundation

/// Fixed v1 category list (RFC §3.3). Stored on a transaction as a raw `String`
/// (not this enum) so that user-defined categories in v2 remain an additive
/// migration. Use `rawValue` for persistence/CSV and `displayName` for UI.
public enum SpendingCategory: String, CaseIterable, Sendable {
    case food = "Food"
    case groceries = "Groceries"
    case transport = "Transport/Gas"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case bills = "Bills & Utilities"
    case health = "Health"
    case travel = "Travel"
    case other = "Other"

    /// Default for new manual entries and all automation-logged entries.
    public static let `default`: SpendingCategory = .other

    /// Human-readable label (identical to the stored raw value in v1).
    public var displayName: String { rawValue }

    /// Maps an arbitrary stored string back to a known case, falling back to
    /// `.other` for values outside the fixed list (forward-compat safety).
    public static func from(stored raw: String) -> SpendingCategory {
        SpendingCategory(rawValue: raw) ?? .other
    }
}
