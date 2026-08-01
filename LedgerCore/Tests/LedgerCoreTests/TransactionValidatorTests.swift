import Testing
import Foundation
@testable import LedgerCore

@Suite struct TransactionValidatorTests {

    @Test func validDraftProducesValue() {
        let draft = TransactionDraft(
            amountText: "23.50", kind: .expense, category: "Groceries",
            source: "Cash", date: day(2026, 8, 1), merchant: "Village Grocer"
        )
        let result = TransactionValidator.validate(draft, locale: enUS)
        #expect(result.isValid)
        #expect(result.value?.amount == dec("23.50"))
        #expect(result.value?.source == "Cash")
        #expect(result.value?.merchant == "Village Grocer")
    }

    @Test func trimsMerchantToNilWhenBlank() {
        let draft = TransactionDraft(amountText: "5", source: "Cash", merchant: "   ")
        #expect(TransactionValidator.validate(draft, locale: enUS).value?.merchant == nil)
    }

    @Test func defaultsBlankCategoryToOther() {
        let draft = TransactionDraft(amountText: "5", category: "  ", source: "Cash")
        #expect(TransactionValidator.validate(draft, locale: enUS).value?.category == "Other")
    }

    @Test func invalidAmountReportsError() {
        let draft = TransactionDraft(amountText: "-5", source: "Cash")
        let result = TransactionValidator.validate(draft, locale: enUS)
        #expect(!result.isValid)
        #expect(result.errors.contains(.amountInvalid))
    }

    @Test func emptySourceReportsError() {
        let draft = TransactionDraft(amountText: "5", source: "   ")
        let result = TransactionValidator.validate(draft, locale: enUS)
        #expect(!result.isValid)
        #expect(result.errors.contains(.sourceEmpty))
    }

    @Test func reportsBothErrorsTogether() {
        let result = TransactionValidator.validate(TransactionDraft(amountText: "", source: ""), locale: enUS)
        #expect(result.errors.contains(.amountInvalid))
        #expect(result.errors.contains(.sourceEmpty))
    }

    @Test func makeTransactionCarriesEntryMethodAndFields() {
        let draft = TransactionDraft(amountText: "5", source: "Cash", merchant: "Kopi")
        let validated = try! #require(TransactionValidator.validate(draft, locale: enUS).value)
        let record = validated.makeTransaction(entryMethod: .automation)
        #expect(record.entryMethod == .automation)
        #expect(record.amount == dec("5"))
        #expect(record.merchant == "Kopi")
    }
}
