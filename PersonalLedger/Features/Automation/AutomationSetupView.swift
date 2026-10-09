import SwiftUI

/// In-app guide for creating the Shortcuts automation by hand (RFC §FR-4) — iOS
/// gives apps no way to install one. Labels follow iOS 26, with the iOS 17–18
/// names alongside where they differ.
struct AutomationSetupView: View {
    @Environment(\.openURL) private var openURL
    @State private var couldNotOpenShortcuts = false

    /// Opens Shortcuts on its New Automation screen. Not documented by Apple, so
    /// `shortcutsApp` is the fallback if a future iOS stops accepting it.
    private static let newAutomationURL = URL(string: "shortcuts://create-automation")!
    private static let shortcutsAppURL = URL(string: "shortcuts://")!

    private static let appName =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "this app"

    private static let steps: [String] = [
        "Tap **Open Shortcuts** above. If it doesn't land on a new automation, open the **Automation** tab and tap **+**.",
        "Choose **Wallet** (named **Transaction** on iOS 17 and 18).",
        "Under **When I tap**, select the cards to track. Leave every category selected.",
        "Choose **Run Immediately**, turn off **Notify When Run**, then tap **Next**.",
        "Tap **Create New Shortcut** (or **New Blank Automation**) and add the **Log Transaction** action from **\(appName)**.",
        "In the action, tap **Amount**, choose **Shortcut Input**, then tap it again and pick **Amount**.",
        "Do the same for **Merchant** and **Card**, picking the matching field each time.",
        "Tap **Done**. Your next Apple Pay payment appears in the ledger.",
    ]

    private static let notes: [String] = [
        "Only Apple Pay payments are logged. Physical-card purchases, online payments and refunds still need adding by hand.",
        "Entries arrive under **Other**. Tap a row to change its category.",
        "Cards are labelled “Apple Pay – card name” until you rename them in **Settings → Card names**.",
        "If the automation fires twice for one payment, the repeat is skipped (same amount and merchant within a minute).",
    ]

    var body: some View {
        List {
            Section {
                Text("iOS doesn't let apps create automations, so this one is set up once by hand in Shortcuts. It takes about a minute.")
                    .foregroundStyle(.secondary)
                Button("Open Shortcuts") { openShortcuts() }
                    .buttonStyle(PrimaryButtonStyle())
                    .listRowSeparator(.hidden)
            }
            Section("Steps") {
                ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text(LocalizedStringKey(step))
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            Section("Good to know") {
                ForEach(Self.notes, id: \.self) { note in
                    Text(LocalizedStringKey(note))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Auto-logging")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Couldn't open Shortcuts", isPresented: $couldNotOpenShortcuts) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Open the Shortcuts app from your Home Screen and follow the steps. If it has been removed, reinstall it from the App Store.")
        }
    }

    private func openShortcuts() {
        openURL(Self.newAutomationURL) { accepted in
            guard !accepted else { return }
            openURL(Self.shortcutsAppURL) { accepted in
                couldNotOpenShortcuts = !accepted
            }
        }
    }
}

#Preview {
    NavigationStack { AutomationSetupView() }
}
