import Testing
import Foundation
@testable import LedgerCore

@Suite struct LedgerQueryTests {

    // effective amounts: Cash 10, Maybank 5, Cash refund -20
    private var sample: [TransactionData] {
        [
            tx(amount: "10.00", source: "Cash", date: day(2026, 8, 3)),
            tx(amount: "5.00", source: "Maybank", date: day(2026, 8, 1)),
            tx(amount: "20.00", source: "Cash", date: day(2026, 8, 2), kind: .refund),
        ]
    }

    @Test func distinctSourcesSortedUnique() {
        #expect(LedgerQuery.distinctSources(in: sample) == ["Cash", "Maybank"])
    }

    @Test func filterBySource() {
        #expect(LedgerQuery.filter(source: "Cash", in: sample).count == 2)
        #expect(LedgerQuery.filter(source: nil, in: sample).count == 3)
        #expect(LedgerQuery.filter(source: "", in: sample).count == 3)
    }

    @Test func sortByDate() {
        #expect(LedgerQuery.sorted(sample, by: .dateNewest).map(\.date)
                == [day(2026, 8, 3), day(2026, 8, 2), day(2026, 8, 1)])
        #expect(LedgerQuery.sorted(sample, by: .dateOldest).map(\.date)
                == [day(2026, 8, 1), day(2026, 8, 2), day(2026, 8, 3)])
    }

    @Test func sortByAmountUsesEffective() {
        #expect(LedgerQuery.sorted(sample, by: .amountHighest).map(\.effectiveAmount)
                == [dec("10.00"), dec("5.00"), dec("-20.00")])
        #expect(LedgerQuery.sorted(sample, by: .amountLowest).map(\.effectiveAmount)
                == [dec("-20.00"), dec("5.00"), dec("10.00")])
    }

    @Test func visibleFiltersThenSorts() {
        let visible = LedgerQuery.visible(sample, source: "Cash", sort: .amountHighest)
        #expect(visible.map(\.effectiveAmount) == [dec("10.00"), dec("-20.00")])
    }
}
