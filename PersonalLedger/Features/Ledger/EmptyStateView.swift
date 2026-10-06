import SwiftUI

/// Shown when the list has no rows — either the month is empty or a filter
/// matched nothing (RFC §FR-1, improvement #1).
struct EmptyStateView: View {
    var message: String = "No transactions yet this month"

    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
