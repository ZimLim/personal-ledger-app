import Foundation

/// Immutable, platform-agnostic representation of a single transaction.
///
/// This is the value type all pure logic (totals, grouping, CSV, dedupe) works
/// on. The SwiftData `@Model Transaction` in the app target maps to/from this —
/// keeping business rules testable without SwiftData. Per the project's
/// immutability rule every field is `let`; "edits" construct a new value.
public struct TransactionData: Identifiable, Equatable, Sendable {
    public let id: UUID
    /// Always stored positive (RFC §3.1); sign comes from `kind`.
    public let amount: Decimal
    public let currencyCode: String
    public let source: String
    public let date: Date
    public let merchant: String?
    public let kind: TransactionKind
    /// Stored as a raw string for v2 forward-compat (see `SpendingCategory`).
    public let category: String
    public let entryMethod: EntryMethod
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        amount: Decimal,
        currencyCode: String = "MYR",
        source: String,
        date: Date,
        merchant: String? = nil,
        kind: TransactionKind = .expense,
        category: String = SpendingCategory.default.rawValue,
        entryMethod: EntryMethod = .manual,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.currencyCode = currencyCode
        self.source = source
        self.date = date
        self.merchant = merchant
        self.kind = kind
        self.category = category
        self.entryMethod = entryMethod
        self.createdAt = createdAt
    }

    /// Signed value used in every sum (refunds negative) — RFC §3.1.
    public var effectiveAmount: Decimal {
        Money.effective(amount: amount, kind: kind)
    }
}
