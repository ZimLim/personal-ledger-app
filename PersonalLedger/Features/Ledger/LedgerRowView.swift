import SwiftUI
import LedgerCore

/// One transaction row (RFC §FR-1): effective amount prominent (refunds show a
/// minus and a "Refund" tag), merchant (or "—"), category, source, day of month.
struct LedgerRowView: View {
    let transaction: Transaction

    private var data: TransactionData { transaction.data }
    private var dayOfMonth: Int { Calendar.current.component(.day, from: data.date) }
    private var merchantText: String {
        let m = data.merchant ?? ""
        return m.isEmpty ? "—" : m
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(merchantText)
                    .font(.body)
                HStack(spacing: 6) {
                    Text(data.category)
                    Text("·")
                    Text(data.source)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(MoneyFormatter.displayEffective(data.effectiveAmount))
                    .font(.body)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .foregroundStyle(data.kind == .refund ? .secondary : .primary)
                HStack(spacing: 6) {
                    if data.kind == .refund {
                        Text("Refund")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                    Text("Day \(dayOfMonth)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
