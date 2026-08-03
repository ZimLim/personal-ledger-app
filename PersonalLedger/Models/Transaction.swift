import Foundation
import SwiftData
import LedgerCore

/// SwiftData persistence model. This is a storage detail — all business logic
/// operates on `LedgerCore.TransactionData` (see `Transaction+Mapping`). Enums
/// are stored as their raw `String` (like `category`) to keep schema migration
/// additive.
@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var currencyCode: String
    var source: String
    var date: Date
    var merchant: String?
    var kindRaw: String
    var category: String
    var entryMethodRaw: String
    var createdAt: Date

    init(
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
        self.kindRaw = kind.rawValue
        self.category = category
        self.entryMethodRaw = entryMethod.rawValue
        self.createdAt = createdAt
    }
}
