import SwiftData

/// The app's one `ModelContainer`. The UI scene and `LogTransactionIntent` both
/// use it (and its `mainContext`), so a transaction written by the automation
/// while the app is open appears in the live `@Query` — two containers over the
/// same store would not refresh each other.
enum ModelContainerFactory {

    /// The on-device store at SwiftData's default location — the same file the
    /// scene's `.modelContainer(for:)` used before, so existing data carries over.
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: Transaction.self)
        } catch {
            // Unrecoverable: there is no ledger without the store. Crash rather
            // than fall back to an empty store, which would hide the user's data.
            fatalError("Could not open the ledger store: \(error)")
        }
    }()
}
