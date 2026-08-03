import Foundation
import LedgerCore

/// Bridges the SwiftData `@Model` to the immutable domain value type that all
/// pure logic in `LedgerCore` consumes.
extension Transaction {

    var kind: TransactionKind { TransactionKind(rawValue: kindRaw) ?? .expense }
    var entryMethod: EntryMethod { EntryMethod(rawValue: entryMethodRaw) ?? .manual }

    /// Snapshot into the pure domain value type.
    var data: TransactionData {
        TransactionData(
            id: id,
            amount: amount,
            currencyCode: currencyCode,
            source: source,
            date: date,
            merchant: merchant,
            kind: kind,
            category: category,
            entryMethod: entryMethod,
            createdAt: createdAt
        )
    }

    /// Build a persistence model from a domain value.
    convenience init(data: TransactionData) {
        self.init(
            id: data.id,
            amount: data.amount,
            currencyCode: data.currencyCode,
            source: data.source,
            date: data.date,
            merchant: data.merchant,
            kind: data.kind,
            category: data.category,
            entryMethod: data.entryMethod,
            createdAt: data.createdAt
        )
    }

    /// Apply edited fields. `entryMethod` is intentionally NOT updated — it is
    /// immutable after creation (RFC §FR-7), so provenance is always preserved.
    func update(from data: TransactionData) {
        amount = data.amount
        currencyCode = data.currencyCode
        source = data.source
        date = data.date
        merchant = data.merchant
        kindRaw = data.kind.rawValue
        category = data.category
    }
}
