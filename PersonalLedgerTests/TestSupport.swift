import Foundation
import SwiftData
@testable import PersonalLedger

/// A repository over a throwaway in-memory store, plus its context for direct
/// fetches in assertions.
@MainActor
func makeInMemoryRepository() throws -> (SwiftDataTransactionRepository, ModelContext) {
    let container = try ModelContainer(
        for: Transaction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    return (SwiftDataTransactionRepository(context: context), context)
}

/// An isolated `UserDefaults` suite that removes itself when released, so tests
/// never read or leave behind real preferences.
final class ScratchDefaults {
    let defaults: UserDefaults
    private let suiteName: String

    init() {
        suiteName = "PersonalLedgerTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
