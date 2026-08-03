import SwiftUI
import LedgerCore

/// Slide-over history drawer (RFC §FR-3): months grouped by year, newest first,
/// each showing its total. Only months with transactions are listed, plus the
/// current month (always). Selecting a month switches the ledger.
struct LedgerSidebarView: View {
    let transactions: [Transaction]
    let selectedMonth: YearMonth
    let onSelect: (YearMonth) -> Void

    private var currentMonth: YearMonth { YearMonth(date: Date()) }

    private var months: [LedgerMonth] {
        var list = LedgerGrouping.byMonth(transactions.map(\.data))
        if !list.contains(where: { $0.month == currentMonth }) {
            list.append(LedgerMonth(month: currentMonth, transactions: []))
            list.sort { $0.month > $1.month }
        }
        return list
    }

    private var byYear: [(year: Int, months: [LedgerMonth])] {
        Dictionary(grouping: months, by: { $0.month.year })
            .map { (year: $0.key, months: $0.value.sorted { $0.month > $1.month }) }
            .sorted { $0.year > $1.year }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Ledgers")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            List {
                ForEach(byYear, id: \.year) { group in
                    Section(String(group.year)) {
                        ForEach(group.months, id: \.month) { ledgerMonth in
                            monthRow(ledgerMonth)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
    }

    private func monthRow(_ ledgerMonth: LedgerMonth) -> some View {
        Button {
            onSelect(ledgerMonth.month)
        } label: {
            HStack {
                Text(ledgerMonth.month.monthName())
                if ledgerMonth.month == currentMonth {
                    Text("(current)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(MoneyFormatter.displayEffective(ledgerMonth.total))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .fontWeight(ledgerMonth.month == selectedMonth ? .semibold : .regular)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
