import Foundation
import Observation
import LedgerCore

/// Drives the Add/Edit sheet (RFC §FR-2, §FR-7). Holds an editable
/// `TransactionDraft`, exposes validity/change state for the Save button, and
/// persists via the repository. All validation is delegated to `LedgerCore`.
@MainActor
@Observable
final class TransactionFormModel {
    enum Mode {
        case add(defaultDate: Date)
        case edit(Transaction)
    }

    var draft: TransactionDraft

    private let repository: TransactionRepository
    private let editingModel: Transaction?
    private let original: TransactionData?

    init(mode: Mode, repository: TransactionRepository) {
        self.repository = repository
        switch mode {
        case .add(let date):
            self.draft = TransactionDraft(date: date)
            self.editingModel = nil
            self.original = nil
        case .edit(let model):
            self.draft = TransactionDraft(editing: model.data)
            self.editingModel = model
            self.original = model.data
        }
    }

    var isEditing: Bool { editingModel != nil }

    /// Save is enabled only when the draft is valid AND, when editing, something
    /// actually changed (RFC §FR-7).
    var canSave: Bool {
        guard let validated = TransactionValidator.validate(draft).value else { return false }
        guard let original else { return true } // adding
        return validated.amount != original.amount
            || validated.kind != original.kind
            || validated.category != original.category
            || validated.source != original.source
            || validated.date != original.date
            || validated.merchant != original.merchant
    }

    func save() throws {
        guard let validated = TransactionValidator.validate(draft).value else { return }
        if let model = editingModel {
            let updated = validated.makeTransaction(
                id: model.id, entryMethod: model.entryMethod, createdAt: model.createdAt
            )
            try repository.update(model, with: updated)
        } else {
            try repository.create(validated.makeTransaction(entryMethod: .manual))
        }
    }

    func deleteIfEditing() throws {
        if let model = editingModel { try repository.delete(model) }
    }
}
