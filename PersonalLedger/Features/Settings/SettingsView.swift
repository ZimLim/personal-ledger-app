import SwiftUI

/// Minimal settings sheet (RFC §7 screen 5). Holds the Apple Pay auto-logging
/// entry points for now; export shortcuts join it with Phase 2.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("Set up auto-logging") { AutomationSetupView() }
                    NavigationLink("Card names") { CardMappingView() }
                } header: {
                    Text("Apple Pay")
                } footer: {
                    Text("Log Apple Pay payments into the ledger automatically, using a Shortcuts automation.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
