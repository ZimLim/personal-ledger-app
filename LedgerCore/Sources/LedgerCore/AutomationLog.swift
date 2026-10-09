import Foundation

/// The raw values the Shortcuts Wallet ("Transaction") trigger hands to
/// `LogTransactionIntent` (RFC §FR-4), exactly as received.
public struct AutomationLogRequest: Equatable, Sendable {
    public let amountText: String
    public let merchant: String?
    public let card: String?

    public init(amountText: String, merchant: String? = nil, card: String? = nil) {
        self.amountText = amountText
        self.merchant = merchant
        self.card = card
    }
}

/// What to do with an `AutomationLogRequest`.
public enum AutomationLogDecision: Equatable, Sendable {
    /// Persist this entry.
    case log(TransactionData)
    /// The trigger fired twice for one purchase (RFC §5.2) — write nothing.
    case skipDuplicate
    /// The request carries no usable amount — write nothing.
    case rejectInvalidAmount
}

/// Pure rules for automation logging (RFC §FR-4): turn a trigger's raw values
/// into an `automation` expense dated now, categorised "Other", with the card
/// mapped to a source — or decide it must not be written. The app target's
/// `TransactionLogService` supplies the nearby entries and persists the result.
public enum AutomationLog {

    /// - Parameter existing: entries to dedupe against; only those within
    ///   `DuplicateGuard.defaultWindow` of `now` can matter.
    public static func decide(
        _ request: AutomationLogRequest,
        existing: [TransactionData],
        cardMapping: [String: String] = [:],
        now: Date,
        locale: Locale = .current
    ) -> AutomationLogDecision {
        guard let amount = AutomationAmount.parse(request.amountText, locale: locale) else {
            return .rejectInvalidAmount
        }

        // A missing merchant is valid for automation entries (RFC §8).
        let merchant = (request.merchant ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = TransactionData(
            amount: amount,
            source: CardSourceResolver.source(forCard: request.card, mapping: cardMapping),
            date: now,
            merchant: merchant.isEmpty ? nil : merchant,
            kind: .expense,
            category: SpendingCategory.default.rawValue,
            entryMethod: .automation,
            createdAt: now
        )
        return DuplicateGuard.isDuplicate(of: entry, in: existing) ? .skipDuplicate : .log(entry)
    }
}
