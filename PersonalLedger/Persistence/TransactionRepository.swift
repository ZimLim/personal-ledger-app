import Foundation
import SwiftData
import LedgerCore

/// Write + non-reactive read access to the transaction store. SwiftUI views read
/// reactively via `@Query`; this repository handles mutations and the queries
/// needed off-view (recent sources for the form, and later the App Intent).
@MainActor
protocol TransactionRepository {
    func create(_ data: TransactionData) throws
    func update(_ transaction: Transaction, with data: TransactionData) throws
    func delete(_ transaction: Transaction) throws
    func allData() throws -> [TransactionData]
    /// Transactions dated within the closed range, newest first (the automation
    /// dedupe window).
    func data(from start: Date, through end: Date) throws -> [TransactionData]
    /// Distinct sources, most-recently-used first (for the Add form's quick chips).
    func distinctSources(limit: Int) throws -> [String]
}

@MainActor
final class SwiftDataTransactionRepository: TransactionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func create(_ data: TransactionData) throws {
        context.insert(Transaction(data: data))
        try context.save()
    }

    func update(_ transaction: Transaction, with data: TransactionData) throws {
        transaction.update(from: data)
        try context.save()
    }

    func delete(_ transaction: Transaction) throws {
        context.delete(transaction)
        try context.save()
    }

    func allData() throws -> [TransactionData] {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).map(\.data)
    }

    func data(from start: Date, through end: Date) throws -> [TransactionData] {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.date >= start && $0.date <= end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).map(\.data)
    }

    func distinctSources(limit: Int = 8) throws -> [String] {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        var seen = Set<String>()
        var result: [String] = []
        for transaction in try context.fetch(descriptor) {
            if seen.insert(transaction.source).inserted {
                result.append(transaction.source)
                if result.count >= limit { break }
            }
        }
        return result
    }
}
