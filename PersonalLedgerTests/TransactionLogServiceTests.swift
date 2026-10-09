import Testing
import SwiftData
import Foundation
@testable import PersonalLedger
import LedgerCore

/// The automation write path (RFC §FR-4) against an in-memory store — the same
/// service `LogTransactionIntent` calls.
@MainActor
@Suite struct TransactionLogServiceTests {

    private let scratch = ScratchDefaults()
    private let tapTime = Date(timeIntervalSince1970: 1_790_000_000)
    private let request = AutomationLogRequest(
        amountText: "RM 23.50", merchant: "Village Grocer", card: "BigPay Visa"
    )

    private func service(_ repository: TransactionRepository, at now: Date) -> TransactionLogService {
        TransactionLogService(
            repository: repository,
            cardMapping: CardMappingStore(defaults: scratch.defaults),
            now: { now }
        )
    }

    @Test func persistsAnAutomationExpense() throws {
        let (repo, _) = try makeInMemoryRepository()

        let decision = try service(repo, at: tapTime).log(request)

        let stored = try #require(try repo.allData().first)
        #expect(decision == .log(stored))
        #expect(stored.amount == Decimal(string: "23.50"))
        #expect(stored.merchant == "Village Grocer")
        #expect(stored.source == "Apple Pay – BigPay Visa")
        #expect(stored.entryMethod == .automation)
        #expect(stored.kind == .expense)
        #expect(stored.category == "Other")
        #expect(stored.date == tapTime)
    }

    @Test func usesTheStoredCardMapping() throws {
        let (repo, _) = try makeInMemoryRepository()
        CardMappingStore(defaults: scratch.defaults).setSource("BigPay", forCard: "BigPay Visa")

        try service(repo, at: tapTime).log(request)

        #expect(try repo.allData().first?.source == "BigPay")
    }

    @Test func skipsARepeatTriggerWithinTheWindow() throws {
        let (repo, _) = try makeInMemoryRepository()
        try service(repo, at: tapTime).log(request)

        let second = try service(repo, at: tapTime.addingTimeInterval(10)).log(request)

        #expect(second == .skipDuplicate)
        #expect(try repo.allData().count == 1)
    }

    @Test func logsTheSamePurchaseAgainAfterTheWindow() throws {
        let (repo, _) = try makeInMemoryRepository()
        try service(repo, at: tapTime).log(request)

        try service(repo, at: tapTime.addingTimeInterval(300)).log(request)

        #expect(try repo.allData().count == 2)
    }

    @Test func writesNothingForAnUnreadableAmount() throws {
        let (repo, _) = try makeInMemoryRepository()
        let empty = AutomationLogRequest(amountText: " ", merchant: "Village Grocer", card: "BigPay Visa")

        let decision = try service(repo, at: tapTime).log(empty)

        #expect(decision == .rejectInvalidAmount)
        #expect(try repo.allData().isEmpty)
    }
}
