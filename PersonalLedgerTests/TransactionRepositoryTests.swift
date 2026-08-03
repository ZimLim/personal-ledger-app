import Testing
import SwiftData
import Foundation
@testable import PersonalLedger
import LedgerCore

@MainActor
@Suite struct TransactionRepositoryTests {

    private func makeRepo() throws -> (SwiftDataTransactionRepository, ModelContext) {
        let container = try ModelContainer(
            for: Transaction.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        return (SwiftDataTransactionRepository(context: context), context)
    }

    @Test func createThenFetch() throws {
        let (repo, _) = try makeRepo()
        try repo.create(TransactionData(amount: 10, source: "Cash", date: Date()))
        let all = try repo.allData()
        #expect(all.count == 1)
        #expect(all.first?.source == "Cash")
    }

    @Test func distinctSourcesAreMostRecentFirst() throws {
        let (repo, _) = try makeRepo()
        try repo.create(TransactionData(amount: 1, source: "Cash", date: Date(), createdAt: Date(timeIntervalSince1970: 100)))
        try repo.create(TransactionData(amount: 2, source: "Maybank", date: Date(), createdAt: Date(timeIntervalSince1970: 200)))
        try repo.create(TransactionData(amount: 3, source: "Cash", date: Date(), createdAt: Date(timeIntervalSince1970: 300)))
        #expect(try repo.distinctSources(limit: 8) == ["Cash", "Maybank"])
    }

    @Test func deleteRemoves() throws {
        let (repo, context) = try makeRepo()
        try repo.create(TransactionData(amount: 5, source: "Cash", date: Date()))
        let model = try #require(context.fetch(FetchDescriptor<Transaction>()).first)
        try repo.delete(model)
        #expect(try repo.allData().isEmpty)
    }

    @Test func updatePersistsButKeepsEntryMethod() throws {
        let (repo, context) = try makeRepo()
        try repo.create(TransactionData(amount: 5, source: "Cash", date: Date(), entryMethod: .automation))
        let model = try #require(context.fetch(FetchDescriptor<Transaction>()).first)
        let edited = TransactionData(
            id: model.id, amount: 9, source: "Maybank", date: model.date,
            kind: .expense, entryMethod: .manual, createdAt: model.createdAt
        )
        try repo.update(model, with: edited)
        let reloaded = try #require(try repo.allData().first)
        #expect(reloaded.amount == 9)
        #expect(reloaded.source == "Maybank")
        #expect(reloaded.entryMethod == .automation)
    }
}
