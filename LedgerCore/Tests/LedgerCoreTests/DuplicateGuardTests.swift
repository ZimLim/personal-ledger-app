import Testing
import Foundation
@testable import LedgerCore

@Suite struct DuplicateGuardTests {

    private func automation(amount: String, merchant: String?, date: Date) -> TransactionData {
        tx(amount: amount, source: "Apple Pay", date: date, merchant: merchant, entryMethod: .automation)
    }

    @Test func flagsMatchWithinWindow() {
        let existing = [automation(amount: "23.50", merchant: "Village Grocer", date: day(2026, 8, 1, minute: 0))]
        let candidate = automation(amount: "23.50", merchant: "Village Grocer", date: day(2026, 8, 1, minute: 0)).with(seconds: 30)
        #expect(DuplicateGuard.isDuplicate(of: candidate, in: existing))
    }

    @Test func allowsMatchOutsideWindow() {
        let existing = [automation(amount: "23.50", merchant: "Village Grocer", date: day(2026, 8, 1, minute: 0))]
        let candidate = automation(amount: "23.50", merchant: "Village Grocer", date: day(2026, 8, 1, minute: 5))
        #expect(!DuplicateGuard.isDuplicate(of: candidate, in: existing))
    }

    @Test func differentMerchantIsNotDuplicate() {
        let existing = [automation(amount: "23.50", merchant: "Village Grocer", date: day(2026, 8, 1))]
        let candidate = automation(amount: "23.50", merchant: "Jaya Grocer", date: day(2026, 8, 1))
        #expect(!DuplicateGuard.isDuplicate(of: candidate, in: existing))
    }

    @Test func manualEntriesAreNeverDeduped() {
        let existing = [tx(amount: "23.50", date: day(2026, 8, 1), merchant: "Village Grocer", entryMethod: .manual)]
        let candidate = automation(amount: "23.50", merchant: "Village Grocer", date: day(2026, 8, 1))
        #expect(!DuplicateGuard.isDuplicate(of: candidate, in: existing))
    }

    @Test func doesNotMatchItself() {
        let entry = automation(amount: "23.50", merchant: "Village Grocer", date: day(2026, 8, 1))
        #expect(!DuplicateGuard.isDuplicate(of: entry, in: [entry]))
    }
}

private extension TransactionData {
    /// Copy with the date shifted by `seconds` (tests build near-duplicates).
    func with(seconds: TimeInterval) -> TransactionData {
        TransactionData(
            id: id, amount: amount, currencyCode: currencyCode, source: source,
            date: date.addingTimeInterval(seconds), merchant: merchant, kind: kind,
            category: category, entryMethod: entryMethod, createdAt: createdAt
        )
    }
}
