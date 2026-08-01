import Foundation

/// Whether a transaction reduces (`expense`) or increases (`refund`) available money.
///
/// The stored `amount` is always positive; `kind` determines its sign in totals
/// and CSV export (RFC §3.1). Users never type a negative number — a refund is
/// chosen via an explicit toggle.
public enum TransactionKind: String, Codable, CaseIterable, Sendable {
    case expense
    case refund

    /// Multiplier applied to a positive stored amount to get its effective value.
    public var sign: Int {
        switch self {
        case .expense: return 1
        case .refund: return -1
        }
    }
}
