import Foundation

/// Parses the amount handed over by the Shortcuts Wallet ("Transaction") trigger
/// (RFC §5.2). Shortcuts passes it as text that can carry a currency symbol or
/// code and grouping separators ("RM 23.50", "ARS 23,400.00"), so the intent
/// takes a `String` and the amount stays `Decimal` end-to-end — never `Double`.
///
/// Lenient about how a number is written, strict about whether there is exactly
/// one: a wrong amount logged silently is worse than a failed run the user sees.
/// Text with no number, several numbers, a zero, a minus sign, or malformed
/// separators is rejected rather than guessed at.
public enum AutomationAmount {

    private static let separators: Set<Character> = [".", ","]
    private static let digits: ClosedRange<Character> = "0"..."9"

    /// Digit groups joined by single separators or grouping marks (space,
    /// apostrophe) — so the match always starts and ends on a digit.
    private static let numberPattern = #"[0-9]+(?:[.,'’\s][0-9]+)*"#

    /// - Returns: a positive amount rounded to 2 dp (half up), or `nil` when the
    ///   text holds no usable amount. Refunds are never inferred from a sign
    ///   (RFC §5.4), so a negative amount is rejected.
    public static func parse(_ raw: String, locale: Locale = .current) -> Decimal? {
        guard !raw.contains(where: marksNegative),
              let run = raw.range(of: numberPattern, options: .regularExpression),
              !raw[run.upperBound...].contains(where: digits.contains),
              !hasSeparatorGluedBefore(run.lowerBound, in: raw),
              let canonical = canonicalize(raw[run], locale: locale),
              let value = Decimal(string: canonical, locale: Money.posix)
        else { return nil }

        let rounded = Money.rounded(value)
        return rounded > 0 ? rounded : nil
    }

    /// A minus in any spelling: hyphen, en dash, "−", or accounting parentheses.
    private static func marksNegative(_ character: Character) -> Bool {
        character == "\u{2212}" || character == "("
            || character.unicodeScalars.contains { $0.properties.generalCategory == .dashPunctuation }
    }

    /// ".50" could be 0.50 or, as in "Rs.50", an abbreviation followed by 50.
    private static func hasSeparatorGluedBefore(_ start: String.Index, in text: String) -> Bool {
        guard start > text.startIndex else { return false }
        return separators.contains(text[text.index(before: start)])
    }

    /// Rewrite "1,234.56" / "1.234,56" / "1 234,5" as a canonical "1234.56".
    private static func canonicalize(_ number: Substring, locale: Locale) -> String? {
        guard let decimal = decimalSeparator(in: number, locale: locale) else {
            return ungrouped(number)
        }
        let parts = number.split(separator: decimal, omittingEmptySubsequences: false)
        guard parts.count == 2, // a decimal point appears once
              parts[1].allSatisfy(digits.contains),
              let whole = ungrouped(parts[0])
        else { return nil }
        return "\(whole).\(parts[1])"
    }

    /// Join thousands groups ("1,234", "1 234", "1'234") into plain digits, or
    /// `nil` unless they run three digits at a time — "23 50" or "1,234,56" is
    /// two numbers or a typo, not an amount.
    private static func ungrouped(_ whole: Substring) -> String? {
        let groups = whole.split(omittingEmptySubsequences: false) { !digits.contains($0) }
        guard let first = groups.first, !first.isEmpty else { return nil }
        guard groups.count > 1 else { return String(first) }
        guard first.count <= 3, groups.dropFirst().allSatisfy({ $0.count == 3 }) else { return nil }
        return groups.joined()
    }

    /// The character acting as the decimal point, or `nil` when every separator
    /// present is a grouping mark.
    private static func decimalSeparator(in number: Substring, locale: Locale) -> Character? {
        switch (number.lastIndex(of: "."), number.lastIndex(of: ",")) {
        case (nil, nil):
            return nil
        case let (dot?, comma?):
            // Both present: whichever comes last is the decimal point.
            return dot > comma ? "." : ","
        case (_?, nil):
            return loneSeparatorIsDecimal(".", in: number, locale: locale) ? "." : nil
        case (nil, _?):
            return loneSeparatorIsDecimal(",", in: number, locale: locale) ? "," : nil
        }
    }

    private static func loneSeparatorIsDecimal(_ separator: Character, in number: Substring, locale: Locale) -> Bool {
        let parts = number.split(separator: separator, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false } // repeated, so it groups thousands
        // Exactly three trailing digits reads as either "1,234" or "1.234"; only
        // the device locale can tell which.
        if parts[1].count == 3 { return locale.decimalSeparator == String(separator) }
        return true
    }
}
