import SwiftUI
import SwiftData

@main
struct PersonalLedgerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(ModelContainerFactory.shared)
    }
}
