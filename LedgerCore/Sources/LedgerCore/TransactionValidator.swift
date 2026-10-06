import Foundation

/// A field that failed validation. Amount, source, and (improvement #6) merchant
/// are required for manual entry.
public enum TransactionFieldError: Equatable, Sendable {
    case amountInvalid
    case sourceEmpty
    case merchantEmpty
}

/// A draft that passed validation — carries the parsed, normalized fields ready
/// to become a persisted transaction.
public struct ValidatedDraft: Equatable, Sendable {
    public let amount: Decimal
    public let kind: TransactionKind
    public let category: String
    public let source: String
    public let date: Date
    public let merchant: String

    /// Build a persistable `TransactionData`. Identity, entry method, and audit
    /// timestamp are supplied by the caller (the repository / intent), not the form.
    public func makeTransaction(
        id: UUID = UUID(),
        entryMethod: EntryMethod = .manual,
        currencyCode: String = "MYR",
        createdAt: Date = Date()
    ) -> TransactionData {
        TransactionData(
            id: id,
            amount: amount,
            currencyCode: currencyCode,
            source: source,
            date: date,
            merchant: merchant,
            kind: kind,
            category: category,
            entryMethod: entryMethod,
            createdAt: createdAt
        )
    }
}

/// Result of validating a `TransactionDraft`.
public struct DraftValidation: Equatable, Sendable {
    public let value: ValidatedDraft?
    public let errors: [TransactionFieldError]

    /// Whether the Save button should be enabled (RFC §FR-2).
    public var isValid: Bool { value != nil }
}

/// Pure validation for the Add/Edit form.
public enum TransactionValidator {

    public static func validate(_ draft: TransactionDraft, locale: Locale = .current) -> DraftValidation {
        var errors: [TransactionFieldError] = []

        let amount = Money.parse(userInput: draft.amountText, locale: locale)
        if amount == nil { errors.append(.amountInvalid) }

        let source = draft.source.trimmingCharacters(in: .whitespacesAndNewlines)
        if source.isEmpty { errors.append(.sourceEmpty) }

        let merchant = draft.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        if merchant.isEmpty { errors.append(.merchantEmpty) }

        guard let amount, errors.isEmpty else {
            return DraftValidation(value: nil, errors: errors)
        }

        let trimmedCategory = draft.category.trimmingCharacters(in: .whitespacesAndNewlines)

        let validated = ValidatedDraft(
            amount: amount,
            kind: draft.kind,
            category: trimmedCategory.isEmpty ? SpendingCategory.default.rawValue : trimmedCategory,
            source: source,
            date: draft.date,
            merchant: merchant
        )
        return DraftValidation(value: validated, errors: [])
    }

    /// Convenience for live Save-button enablement.
    public static func isValid(_ draft: TransactionDraft, locale: Locale = .current) -> Bool {
        validate(draft, locale: locale).isValid
    }
}
