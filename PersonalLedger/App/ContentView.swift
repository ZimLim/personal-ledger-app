import SwiftUI

/// Temporary landing view so the app scaffold builds and launches.
/// TODO(Phase 1): replace with the real `LedgerView` (RFC §FR-1).
struct ContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Personal Ledger")
                .font(.headline)
            Text("Scaffold — Phase 1 UI pending")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
