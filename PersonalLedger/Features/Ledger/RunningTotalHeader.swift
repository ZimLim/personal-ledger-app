import SwiftUI
import LedgerCore

/// Pinned header showing the viewed month and its running total of effective
/// amounts. Stays visible while the list scrolls; can be negative in refund-heavy
/// months (RFC §FR-1).
struct RunningTotalHeader: View {
    let month: YearMonth
    let total: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(month.displayName())
                .font(.title3)
                .fontWeight(.semibold)
            Text(MoneyFormatter.displayEffective(total))
                .font(.largeTitle)
                .fontWeight(.bold)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}
