import AppIntents
import LedgerCore

/// The "Log Transaction" action a Shortcuts Wallet ("Transaction") automation
/// runs after an Apple Pay payment (RFC §FR-4, §5.2). A thin wrapper — the rules
/// live in `TransactionLogService` and `LedgerCore.AutomationLog`.
///
/// Must stay in the app target: the system then runs it inside the app's own
/// process against the app's own store, with no App Group (which a free Apple
/// team cannot provision).
struct LogTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Transaction"
    static let description = IntentDescription(
        "Logs an Apple Pay payment into your ledger. Use it in a Wallet automation."
    )
    static let openAppWhenRun = false

    /// Text rather than a number: the trigger hands over e.g. "RM 23.50", and
    /// parsing it ourselves keeps the amount `Decimal` end-to-end (never `Double`).
    @Parameter(title: "Amount")
    var amount: String

    @Parameter(title: "Merchant")
    var merchant: String?

    @Parameter(title: "Card")
    var card: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) at \(\.$merchant) paid with \(\.$card)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let service = TransactionLogService(
            repository: SwiftDataTransactionRepository(context: ModelContainerFactory.shared.mainContext)
        )
        let request = AutomationLogRequest(amountText: amount, merchant: merchant, card: card)

        switch try service.log(request) {
        case .log(let entry):
            return .result(value: Self.confirmation(for: entry))
        case .skipDuplicate:
            return .result(value: "Already logged, skipped the repeat.")
        case .rejectInvalidAmount:
            throw LogTransactionError.unreadableAmount(amount)
        }
    }

    /// The action's output, e.g. for a "Show Notification" step after it.
    private static func confirmation(for entry: TransactionData) -> String {
        let amount = MoneyFormatter.display(entry.amount)
        guard let merchant = entry.merchant else { return "Logged \(amount)." }
        return "Logged \(amount) at \(merchant)."
    }
}

/// Failures Shortcuts reports to the user when the automation run stops.
enum LogTransactionError: Error, CustomLocalizedStringResourceConvertible {
    case unreadableAmount(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .unreadableAmount(let text):
            "Couldn't read an amount from “\(text)”, so nothing was logged. In the automation, set Amount to Shortcut Input, then pick Amount."
        }
    }
}
