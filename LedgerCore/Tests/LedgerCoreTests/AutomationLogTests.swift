import Testing
import Foundation
@testable import LedgerCore

@Suite struct AutomationLogTests {

    private let now = day(2026, 8, 1, hour: 14, minute: 30)

    private func decide(
        amount: String = "RM 23.50",
        merchant: String? = "Village Grocer",
        card: String? = "BigPay Visa",
        existing: [TransactionData] = [],
        mapping: [String: String] = [:]
    ) -> AutomationLogDecision {
        AutomationLog.decide(
            AutomationLogRequest(amountText: amount, merchant: merchant, card: card),
            existing: existing,
            cardMapping: mapping,
            now: now,
            locale: enUS
        )
    }

    private func entry(_ decision: AutomationLogDecision) -> TransactionData? {
        if case .log(let entry) = decision { return entry }
        return nil
    }

    @Test func buildsAnAutomationExpenseDatedNow() throws {
        let logged = try #require(entry(decide()))
        #expect(logged.amount == dec("23.50"))
        #expect(logged.merchant == "Village Grocer")
        #expect(logged.source == "Apple Pay – BigPay Visa")
        #expect(logged.kind == .expense)
        #expect(logged.category == "Other")
        #expect(logged.entryMethod == .automation)
        #expect(logged.currencyCode == "MYR")
        #expect(logged.date == now)
        #expect(logged.createdAt == now)
    }

    @Test func appliesTheUserCardMapping() throws {
        let logged = try #require(entry(decide(mapping: ["BigPay Visa": "BigPay"])))
        #expect(logged.source == "BigPay")
    }

    @Test func missingCardFallsBackToApplePay() throws {
        let logged = try #require(entry(decide(card: nil)))
        #expect(logged.source == "Apple Pay")
    }

    /// RFC §8: automation entries with a missing merchant are still valid.
    @Test func trimsMerchantAndTreatsBlankAsMissing() throws {
        #expect(try #require(entry(decide(merchant: "  Village Grocer \n"))).merchant == "Village Grocer")
        #expect(try #require(entry(decide(merchant: "   "))).merchant == nil)
        #expect(try #require(entry(decide(merchant: nil))).merchant == nil)
    }

    @Test func rejectsAnUnreadableAmount() {
        #expect(decide(amount: "") == .rejectInvalidAmount)
        #expect(decide(amount: "RM 0.00") == .rejectInvalidAmount)
    }

    @Test func skipsARepeatTriggerInsideTheWindow() {
        let first = tx(
            amount: "23.50", source: "Apple Pay – BigPay Visa",
            date: now.addingTimeInterval(-20), merchant: "village grocer", entryMethod: .automation
        )
        #expect(decide(existing: [first]) == .skipDuplicate)
    }

    @Test func logsTheSamePurchaseAgainOutsideTheWindow() {
        let earlier = tx(
            amount: "23.50", date: now.addingTimeInterval(-300),
            merchant: "Village Grocer", entryMethod: .automation
        )
        #expect(entry(decide(existing: [earlier])) != nil)
    }

    @Test func aMatchingManualEntryDoesNotBlockLogging() {
        let manual = tx(amount: "23.50", date: now, merchant: "Village Grocer", entryMethod: .manual)
        #expect(entry(decide(existing: [manual])) != nil)
    }
}
