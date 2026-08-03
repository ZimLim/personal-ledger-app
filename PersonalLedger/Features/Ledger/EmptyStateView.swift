import SwiftUI

/// Shown when the selected month has no transactions (RFC §FR-1).
struct EmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("No transactions yet this month")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
