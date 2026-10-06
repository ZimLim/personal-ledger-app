import Testing
import Foundation
@testable import LedgerCore

@Suite struct CentsAmountTests {

    @Test func digitsStripsNonDigits() {
        #expect(CentsAmount.digits(in: "1,234.56") == "123456")
        #expect(CentsAmount.digits(in: "RM 12.30") == "1230")
        #expect(CentsAmount.digits(in: "") == "")
    }

    @Test func decimalFillsFromCents() {
        #expect(CentsAmount.decimal(fromDigits: "") == dec("0"))
        #expect(CentsAmount.decimal(fromDigits: "5") == dec("0.05"))
        #expect(CentsAmount.decimal(fromDigits: "50") == dec("0.50"))
        #expect(CentsAmount.decimal(fromDigits: "500") == dec("5.00"))
        #expect(CentsAmount.decimal(fromDigits: "1234") == dec("12.34"))
    }

    @Test func displayAlwaysTwoDecimals() {
        #expect(CentsAmount.display(fromDigits: "") == "0.00")
        #expect(CentsAmount.display(fromDigits: "5") == "0.05")
        #expect(CentsAmount.display(fromDigits: "1234") == "12.34")
        #expect(CentsAmount.display(fromDigits: "123456") == "1234.56")
    }

    @Test func ignoresEmbeddedNonDigits() {
        #expect(CentsAmount.decimal(fromDigits: "1a2b3") == dec("1.23"))
    }
}
