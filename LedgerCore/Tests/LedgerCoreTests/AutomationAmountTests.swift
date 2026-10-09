import Testing
import Foundation
@testable import LedgerCore

@Suite struct AutomationAmountTests {

    private let deDE = Locale(identifier: "de_DE")

    @Test func parsesPlainNumbers() {
        #expect(AutomationAmount.parse("23.50", locale: enUS) == dec("23.50"))
        #expect(AutomationAmount.parse("23.5", locale: enUS) == dec("23.50"))
        #expect(AutomationAmount.parse("23", locale: enUS) == dec("23"))
    }

    @Test(arguments: ["RM 23.50", "RM23.50", "MYR 23.50", "23.50 MYR", "$23.50", "RM\u{00A0}23.50", "  RM 23.50\n"])
    func stripsCurrencyAndWhitespace(text: String) {
        #expect(AutomationAmount.parse(text, locale: enUS) == dec("23.50"))
    }

    @Test func stripsGroupingSeparators() {
        #expect(AutomationAmount.parse("RM 1,234.56", locale: enUS) == dec("1234.56"))
        #expect(AutomationAmount.parse("ARS 23,400.00", locale: enUS) == dec("23400.00"))
        #expect(AutomationAmount.parse("1,234,567", locale: enUS) == dec("1234567"))
        #expect(AutomationAmount.parse("CHF 1'234.50", locale: enUS) == dec("1234.50"))
    }

    /// When both separators appear, the last one is the decimal point — whatever
    /// the device locale says.
    @Test func lastSeparatorIsTheDecimalPoint() {
        #expect(AutomationAmount.parse("1.234,56 €", locale: enUS) == dec("1234.56"))
        #expect(AutomationAmount.parse("1,234.56", locale: deDE) == dec("1234.56"))
        #expect(AutomationAmount.parse("1 234,56 €", locale: enUS) == dec("1234.56"))
        #expect(AutomationAmount.parse("1\u{202F}234,56 €", locale: enUS) == dec("1234.56"))
    }

    @Test func loneSeparatorWithOneOrTwoDigitsIsDecimal() {
        #expect(AutomationAmount.parse("23,50", locale: enUS) == dec("23.50"))
        #expect(AutomationAmount.parse("23.50", locale: deDE) == dec("23.50"))
        #expect(AutomationAmount.parse("23,5", locale: enUS) == dec("23.50"))
    }

    /// "1,234" / "1.234" is ambiguous on its own; the device locale decides.
    @Test func loneSeparatorWithThreeDigitsFollowsLocale() {
        #expect(AutomationAmount.parse("1,234", locale: enUS) == dec("1234"))
        #expect(AutomationAmount.parse("1.234", locale: deDE) == dec("1234"))
        #expect(AutomationAmount.parse("1.234", locale: enUS) == dec("1.23"))
        #expect(AutomationAmount.parse("1,234", locale: deDE) == dec("1.23"))
    }

    @Test func roundsExtraDecimalsHalfUp() {
        #expect(AutomationAmount.parse("23.4999", locale: enUS) == dec("23.50"))
        #expect(AutomationAmount.parse("23.455", locale: enUS) == dec("23.46"))
    }

    @Test(arguments: ["", "   ", "RM", "abc", "RM .", "."])
    func rejectsTextWithoutANumber(text: String) {
        #expect(AutomationAmount.parse(text, locale: enUS) == nil)
    }

    /// The trigger occasionally hands over an empty/zero amount; never log RM 0.00.
    @Test(arguments: ["0", "0.00", "RM 0.00", "0.001"])
    func rejectsZero(text: String) {
        #expect(AutomationAmount.parse(text, locale: enUS) == nil)
    }

    /// Refunds are never inferred from a sign (RFC §5.4) — amounts stay positive.
    @Test(arguments: ["-23.50", "RM -23.50", "-RM 23.50", "\u{2212}23.50", "\u{2013}23.50", "(23.50)"])
    func rejectsNegative(text: String) {
        #expect(AutomationAmount.parse(text, locale: enUS) == nil)
    }

    @Test func rejectsMalformedSeparators() {
        #expect(AutomationAmount.parse("1.234,56.7", locale: enUS) == nil)
    }

    /// More than one number means the wrong field was wired to Amount; picking
    /// one would log a guess.
    @Test func rejectsTextWithMoreThanOneNumber() {
        #expect(AutomationAmount.parse("RM 23.50 at Shop 2", locale: enUS) == nil)
    }

    /// ".50" must never be read as 50: a separator glued to the front leaves the
    /// value ambiguous, so it is refused rather than logged 100x out.
    @Test(arguments: [".50", "RM .50", "RM,50", "Rs.50"])
    func rejectsASeparatorGluedToTheFront(text: String) {
        #expect(AutomationAmount.parse(text, locale: enUS) == nil)
    }

    @Test func acceptsAnAbbreviationDotSetApartFromTheNumber() {
        #expect(AutomationAmount.parse("Rs. 50", locale: enUS) == dec("50"))
    }

    /// Grouping is three digits at a time; anything else is two numbers or a typo.
    @Test(arguments: ["RM 23 50", "1,234,56", "1.234.56", "1234,567.00"])
    func rejectsGroupsThatAreNotThousands(text: String) {
        #expect(AutomationAmount.parse(text, locale: enUS) == nil)
    }
}
