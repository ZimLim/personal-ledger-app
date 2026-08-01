import Foundation

/// Pure money helpers. All amounts are `Decimal` (never `Double`) per RFC §3.1.
///
/// Responsibilities:
///  - deriving the signed *effective* amount from a positive stored amount + kind
///  - parsing/validating user-typed amounts (positive, ≤ 2 dp, locale-aware)
///  - formatting amounts for CSV (2 dp, no grouping, `.`-decimal)
public enum Money {

    /// POSIX locale gives a stable `.` decimal separator and no grouping —
    /// used for both parsing the canonical form and CSV output.
    public static let posix = Locale(identifier: "en_US_POSIX")

    // MARK: Effective value

    /// Signed value used in every total and in CSV: refunds become negative
    /// (RFC §3.1 "Effective amount").
    public static func effective(amount: Decimal, kind: TransactionKind) -> Decimal {
        kind == .refund ? -amount : amount
    }

    // MARK: Parsing user input

    /// Validate and parse a user-typed amount string.
    ///
    /// Rules (RFC §FR-2, §8): must be positive, at most 2 decimal places, no
    /// minus/plus sign (refunds are a toggle, not a typed sign). Locale decimal
    /// and grouping separators are normalized to a canonical `1234.56` form.
    ///
    /// - Returns: a rounded (2 dp) positive `Decimal`, or `nil` if invalid.
    public static func parse(userInput raw: String, locale: Locale = .current) -> Decimal? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        // Reject explicit signs and exponent notation outright.
        guard !trimmed.contains(where: { "+-eE".contains($0) }) else { return nil }

        let normalized = canonicalize(trimmed, locale: locale)

        // Only digits with an optional 1–2 digit fractional part.
        guard normalized.range(of: #"^\d+(\.\d{1,2})?$"#, options: .regularExpression) != nil,
              let value = Decimal(string: normalized, locale: posix),
              value > 0
        else { return nil }

        return rounded(value)
    }

    /// Normalize locale separators to a canonical `1234.56` string:
    /// strip the grouping separator, convert the decimal separator to `.`.
    /// Also treats a lone `,` as a decimal point for comma-decimal locales.
    private static func canonicalize(_ input: String, locale: Locale) -> String {
        var s = input
        if let grouping = locale.groupingSeparator, !grouping.isEmpty {
            s = s.replacingOccurrences(of: grouping, with: "")
        }
        let decimal = locale.decimalSeparator ?? "."
        if decimal != "." {
            s = s.replacingOccurrences(of: decimal, with: ".")
        }
        // Fallback: a single comma-as-decimal (e.g. "12,50") in a locale that
        // didn't advertise `,` as its separator.
        if !s.contains(".") && s.filter({ $0 == "," }).count == 1 {
            s = s.replacingOccurrences(of: ",", with: ".")
        } else {
            s = s.replacingOccurrences(of: ",", with: "")
        }
        return s
    }

    // MARK: Rounding & formatting

    /// Round to 2 dp using standard half-up rounding (money rounds half up).
    public static func rounded(_ value: Decimal) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 2, .plain)
        return result
    }

    /// CSV representation: exactly 2 dp, no thousands separator, `.` decimal,
    /// leading `-` preserved for negative (effective) values (RFC §FR-5).
    public static func csvString(_ value: Decimal) -> String {
        csvFormatter.string(from: rounded(value) as NSDecimalNumber) ?? "0.00"
    }

    // Cached formatter, never mutated after construction. NumberFormatter is
    // documented thread-safe for formatting, so shared read-only use is fine.
    nonisolated(unsafe) private static let csvFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = posix
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()
}
