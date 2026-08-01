import Foundation

/// How a transaction entered the ledger. Never editable after creation (RFC §FR-7)
/// so the provenance of every row is always known.
public enum EntryMethod: String, Codable, CaseIterable, Sendable {
    /// Hand-entered via the Add/Edit sheet.
    case manual
    /// Written by `LogTransactionIntent` from a Shortcuts "Transaction" automation.
    case automation
}
