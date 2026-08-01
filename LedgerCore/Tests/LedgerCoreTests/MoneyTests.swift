import Testing
import Foundation
@testable import LedgerCore

@Suite struct MoneyTests {

    @Test func effectiveExpenseIsPositive() {
        #expect(Money.effective(amount: dec("23.50"), kind: .expense) == dec("23.50"))
    }

    @Test func effectiveRefundIsNegative() {
        #expect(Money.effective(amount: dec("23.50"), kind: .refund) == dec("-23.50"))
    }

    @Test func parsesPlainDecimal() {
        #expect(Money.parse(userInput: "23.50", locale: enUS) == dec("23.50"))
    }

    @Test func parsesIntegerAsWhole() {
        #expect(Money.parse(userInput: "8", locale: enUS) == dec("8"))
    }

    @Test func trimsWhitespace() {
        #expect(Money.parse(userInput: "  12.30 ", locale: enUS) == dec("12.30"))
    }

    @Test func stripsGroupingSeparator() {
        #expect(Money.parse(userInput: "1,234.50", locale: enUS) == dec("1234.50"))
    }

    @Test func handlesCommaDecimalLocale() {
        #expect(Money.parse(userInput: "12,50", locale: Locale(identifier: "de_DE")) == dec("12.50"))
    }

    @Test func rejectsThreeDecimalPlaces() {
        #expect(Money.parse(userInput: "23.567", locale: enUS) == nil)
    }

    @Test func rejectsNegative() {
        #expect(Money.parse(userInput: "-5", locale: enUS) == nil)
    }

    @Test func rejectsZero() {
        #expect(Money.parse(userInput: "0", locale: enUS) == nil)
    }

    @Test func rejectsEmptyAndGarbage() {
        #expect(Money.parse(userInput: "", locale: enUS) == nil)
        #expect(Money.parse(userInput: "abc", locale: enUS) == nil)
        #expect(Money.parse(userInput: "1.2.3", locale: enUS) == nil)
    }

    @Test func csvStringAlwaysTwoDecimals() {
        #expect(Money.csvString(dec("23.5")) == "23.50")
        #expect(Money.csvString(dec("8")) == "8.00")
    }

    @Test func csvStringKeepsNegativeAndDropsGrouping() {
        #expect(Money.csvString(dec("-23.50")) == "-23.50")
        #expect(Money.csvString(dec("1234.5")) == "1234.50")
    }
}
