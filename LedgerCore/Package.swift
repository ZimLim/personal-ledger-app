// swift-tools-version: 6.0
import PackageDescription

// LedgerCore: pure, platform-agnostic domain logic for the Personal Spending
// Tracker. Foundation-only — no SwiftUI/SwiftData/AppIntents — so it builds and
// tests from the CLI (`swift build` / `swift test`) without the Xcode GUI. The
// iOS app target depends on this package; the SwiftData `@Model` maps to/from
// these value types.
let package = Package(
    name: "LedgerCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13), // lets the test suite run on the developer's Mac from CLI
    ],
    products: [
        .library(name: "LedgerCore", targets: ["LedgerCore"]),
    ],
    targets: [
        .target(name: "LedgerCore"),
        .testTarget(name: "LedgerCoreTests", dependencies: ["LedgerCore"]),
    ]
)
