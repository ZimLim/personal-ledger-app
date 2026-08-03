import Testing
import Foundation
@testable import PersonalLedger
import LedgerCore

/// Verifies the SwiftData `@Model` <-> `TransactionData` bridge, including the
/// invariant that `entryMethod` survives edits (RFC §FR-7).
@Suite struct TransactionMappingTests {

    @Test func roundTripsThroughDomainValue() {
        let original = TransactionData(
            amount: Decimal(string: "23.50")!,
            source: "Cash",
            date: Date(timeIntervalSince1970: 1_754_000_000),
            merchant: "Kopi",
            kind: .refund,
            category: "Food",
            entryMethod: .automation
        )
        let back = Transaction(data: original).data
        #expect(back.amount == original.amount)
        #expect(back.kind == .refund)
        #expect(back.entryMethod == .automation)
        #expect(back.merchant == "Kopi")
    }

    @Test func updateKeepsEntryMethodImmutable() {
        let model = Transaction(amount: 5, source: "Cash", date: Date(), entryMethod: .automation)
        let edited = TransactionData(
            id: model.id, amount: 9, source: "Maybank", date: model.date,
            kind: .expense, entryMethod: .manual, createdAt: model.createdAt
        )
        model.update(from: edited)
        #expect(model.amount == 9)
        #expect(model.source == "Maybank")
        #expect(model.entryMethod == .automation) // unchanged despite edit asking for .manual
    }
}
