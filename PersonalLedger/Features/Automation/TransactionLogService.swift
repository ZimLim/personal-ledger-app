import Foundation
import LedgerCore

/// The automation write path (RFC §FR-4): asks `LedgerCore.AutomationLog` what to
/// do with a trigger's raw values, then persists the entry if it should be
/// logged. Kept apart from `LogTransactionIntent` so the whole path is testable
/// against an in-memory store.
@MainActor
struct TransactionLogService {
    private let repository: TransactionRepository
    private let cardMapping: CardMappingStore
    private let now: () -> Date

    init(
        repository: TransactionRepository,
        cardMapping: CardMappingStore = CardMappingStore(),
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.cardMapping = cardMapping
        self.now = now
    }

    /// Writes the entry when the decision is `.log`; returns the decision either
    /// way so the caller can report what happened.
    @discardableResult
    func log(_ request: AutomationLogRequest) throws -> AutomationLogDecision {
        let timestamp = now()
        let window = DuplicateGuard.defaultWindow
        let nearby = try repository.data(
            from: timestamp.addingTimeInterval(-window),
            through: timestamp.addingTimeInterval(window)
        )
        let decision = AutomationLog.decide(
            request, existing: nearby, cardMapping: cardMapping.mapping, now: timestamp
        )
        if case .log(let entry) = decision {
            try repository.create(entry)
        }
        return decision
    }
}
