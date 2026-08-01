import Foundation

/// Display formatting for MYR amounts (RFC §6, greyscale UI shows "RM 23.50").
/// Distinct from `Money.csvString`, which is the machine-readable CSV form.
public enum MoneyFormatter {

    /// Format a *stored positive* amount for display, e.g. "RM 23.50".
    public static func display(_ amount: Decimal) -> String {
        "RM " + (formatter.string(from: Money.rounded(amount) as NSDecimalNumber) ?? "0.00")
    }

    /// Format an *effective* (possibly negative) amount, e.g. "-RM 23.50" for a
    /// refund. Refund rows render with a leading minus (RFC §FR-1).
    public static func displayEffective(_ effective: Decimal) -> String {
        let rounded = Money.rounded(effective)
        let magnitude = rounded < 0 ? -rounded : rounded
        let sign = rounded < 0 ? "-" : ""
        return sign + display(magnitude)
    }

    // Cached, never mutated after construction (see note in `Money`).
    nonisolated(unsafe) private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Money.posix
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        f.groupingSeparator = ","
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()
}
