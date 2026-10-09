import Testing
import Foundation
@testable import PersonalLedger

@Suite struct CardMappingStoreTests {

    private let scratch = ScratchDefaults()
    private var store: CardMappingStore { CardMappingStore(defaults: scratch.defaults) }

    @Test func startsEmpty() {
        #expect(store.mapping.isEmpty)
    }

    @Test func savesTrimmedCardAndSource() {
        #expect(store.setSource("  BigPay ", forCard: " BigPay Visa\n"))
        #expect(store.mapping == ["BigPay Visa": "BigPay"])
    }

    @Test func rejectsBlankCardOrSource() {
        #expect(!store.setSource("BigPay", forCard: "   "))
        #expect(!store.setSource("  ", forCard: "BigPay Visa"))
        #expect(store.mapping.isEmpty)
    }

    @Test func overwritesAnExistingCard() {
        store.setSource("BigPay", forCard: "BigPay Visa")
        store.setSource("BigPay card", forCard: "BigPay Visa")
        #expect(store.mapping == ["BigPay Visa": "BigPay card"])
    }

    @Test func removesOnlyTheNamedCard() {
        store.setSource("BigPay", forCard: "BigPay Visa")
        store.setSource("Maybank", forCard: "Maybank Visa")
        store.removeCard("BigPay Visa")
        #expect(store.mapping == ["Maybank Visa": "Maybank"])
    }

    @Test func persistsAcrossInstances() {
        CardMappingStore(defaults: scratch.defaults).setSource("BigPay", forCard: "BigPay Visa")
        #expect(CardMappingStore(defaults: scratch.defaults).mapping == ["BigPay Visa": "BigPay"])
    }

    /// Stored preferences are external data: anything that is not a
    /// string-to-string dictionary reads as "no mappings", never a crash.
    @Test func treatsAStoredValueOfTheWrongShapeAsEmpty() {
        scratch.defaults.set(["BigPay Visa": 42], forKey: CardMappingStore.defaultsKey)
        #expect(store.mapping.isEmpty)
    }
}
