import Testing
import Foundation
@testable import LedgerCore

@Suite struct CardSourceResolverTests {

    @Test func usesUserMappingWhenPresent() {
        let source = CardSourceResolver.source(
            forCard: "BigPay Visa", mapping: ["BigPay Visa": "Apple Pay – BigPay card"]
        )
        #expect(source == "Apple Pay – BigPay card")
    }

    @Test func fallsBackToApplePayPlusCard() {
        #expect(CardSourceResolver.source(forCard: "BigPay Visa") == "Apple Pay – BigPay Visa")
    }

    @Test func genericFallbackWhenNoCard() {
        #expect(CardSourceResolver.source(forCard: nil) == "Apple Pay")
        #expect(CardSourceResolver.source(forCard: "   ") == "Apple Pay")
    }

    @Test func ignoresBlankMappingValue() {
        let source = CardSourceResolver.source(forCard: "BigPay Visa", mapping: ["BigPay Visa": "  "])
        #expect(source == "Apple Pay – BigPay Visa")
    }

    // MARK: Cards awaiting a mapping

    private func automated(source: String, date: Date = day(2026, 8, 1)) -> TransactionData {
        tx(source: source, date: date, entryMethod: .automation)
    }

    @Test func listsCardsStillOnTheFallbackLabelNewestFirst() {
        let transactions = [
            automated(source: "Apple Pay – Maybank Visa", date: day(2026, 8, 1)),
            automated(source: "Apple Pay – BigPay Visa", date: day(2026, 8, 3)),
            automated(source: "Apple Pay – Maybank Visa", date: day(2026, 8, 2)),
        ]
        #expect(CardSourceResolver.unmappedCards(in: transactions) == ["BigPay Visa", "Maybank Visa"])
    }

    @Test func unmappedCardsSkipsCardsThatAlreadyHaveAMapping() {
        let transactions = [automated(source: "Apple Pay – BigPay Visa")]
        #expect(CardSourceResolver.unmappedCards(in: transactions, mapping: ["BigPay Visa": "BigPay"]).isEmpty)
    }

    @Test func unmappedCardsIgnoresManualAndNonFallbackSources() {
        let transactions = [
            tx(source: "Apple Pay – Typed By Hand", entryMethod: .manual),
            automated(source: "Apple Pay"),
            automated(source: "BigPay"),
        ]
        #expect(CardSourceResolver.unmappedCards(in: transactions).isEmpty)
    }

    /// A mapped label may itself start with "Apple Pay – " (RFC §5.3 example);
    /// it is a chosen source, not a card waiting for a mapping.
    @Test func unmappedCardsIgnoresSourcesProducedByAMapping() {
        let mapping = ["BigPay Visa": "Apple Pay – BigPay card"]
        let transactions = [automated(source: "Apple Pay – BigPay card")]
        #expect(CardSourceResolver.unmappedCards(in: transactions, mapping: mapping).isEmpty)
    }
}
