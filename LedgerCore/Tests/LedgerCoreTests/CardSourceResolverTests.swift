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
}
