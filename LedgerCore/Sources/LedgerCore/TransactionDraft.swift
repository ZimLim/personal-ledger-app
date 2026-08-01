import Foundation

/// The editable state behind the Add/Edit sheet (RFC §FR-2, §FR-7), as a plain
/// value type. The SwiftUI form binds to a copy of this; validation is pure
/// (`TransactionValidator`) so it is fully testable without any UI.
public struct TransactionDraft: Equatable, Sendable {
    public var amountText: String
    public var kind: TransactionKind
    public var category: String
    public var source: String
    public var date: Date
    public var merchant: String

    public init(
        amountText: String = "",
        kind: TransactionKind = .expense,
        category: String = SpendingCategory.default.rawValue,
        source: String = "",
        date: Date = Date(),
        merchant: String = ""
    ) {
        self.amountText = amountText
        self.kind = kind
        self.category = category
        self.source = source
        self.date = date
        self.merchant = merchant
    }

    /// Seed the form from an existing transaction when editing (RFC §FR-7).
    public init(editing t: TransactionData) {
        self.init(
            amountText: MoneyFormatter.display(t.amount).replacingOccurrences(of: "RM ", with: ""),
            kind: t.kind,
            category: t.category,
            source: t.source,
            date: t.date,
            merchant: t.merchant ?? ""
        )
    }
}
