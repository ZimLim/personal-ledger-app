import Foundation

/// Cents-first currency entry (improvement #3): the user types digits and they
/// fill from the cents place up — "5" → 0.05, "50" → 0.50, "1234" → 12.34.
/// The field conceptually holds only digits; this converts between the typed
/// digit string and the amount/display string, so the existing `Money` parser
/// and validator stay unchanged (they still see "12.34").
public enum CentsAmount {

    /// Keep only digit characters from arbitrary field text (strips `.`, `,`, spaces).
    public static func digits(in text: String) -> String {
        String(text.filter(\.isNumber))
    }

    /// Interpret a digit string as integer cents → `Decimal`.
    /// "" → 0, "5" → 0.05, "1234" → 12.34. Non-digits are ignored.
    public static func decimal(fromDigits raw: String) -> Decimal {
        let d = digits(in: raw)
        guard !d.isEmpty, let cents = Int(d) else { return .zero }
        return Decimal(cents) / 100
    }

    /// Two-decimal display for the digits typed so far (no grouping, `.` decimal),
    /// matching what the validator later parses: "" → "0.00", "5" → "0.05",
    /// "1234" → "12.34".
    public static func display(fromDigits raw: String) -> String {
        Money.csvString(decimal(fromDigits: raw))
    }
}
