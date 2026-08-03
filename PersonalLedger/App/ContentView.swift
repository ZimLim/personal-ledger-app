import SwiftUI

struct ContentView: View {
    var body: some View {
        LedgerView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
