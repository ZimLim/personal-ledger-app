# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-user **native iOS app** (Swift · SwiftUI · SwiftData · App Intents) for logging personal spending into monthly ledgers, with Apple Pay auto-logging via a Shortcuts automation and CSV export. Full specification lives in [technical_rfc.md](technical_rfc.md); the build/deploy plan and its current status live in [technical_plan.md](technical_plan.md). Read both before non-trivial work — they are the source of truth, not this file.

Target: iPhone 13 Pro on **iOS 26**, deployment target **iOS 17+**, distributed personally via a **free Apple personal team**.

## Environment reality (read first)

The app is **not yet buildable in this environment.** No `.xcodeproj` exists, and only the Xcode **Command Line Tools** are installed (no full Xcode, no iOS SDK, no Simulator). Worse, this CLT install is internally broken (compiler↔SDK version mismatch), so even `swift build` / `swift test` fail at the manifest/link step.

- **The only verification that works today is `swiftc -parse <file>` (syntax only).** Do not claim any Swift file is type-checked, compiles, or that tests pass until full **Xcode 26** is installed — Xcode 26 is required because the phone runs iOS 26 (older Xcode cannot deploy to it).
- Installing Xcode is a **user action** (Mac App Store, ~7 GB); Claude cannot do it. After install: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer && sudo xcodebuild -license accept`.

## Architecture: pure core vs. platform shell

The codebase is deliberately split into two layers so business logic is testable without Xcode:

- **`LedgerCore/`** — a standalone **Swift Package**, Foundation-only (no SwiftUI/SwiftData/App Intents). All domain rules live here: money parsing/formatting, effective-amount math, month grouping/totals, CSV generation, automation dedupe, card→source mapping, and form validation. It builds and tests from the CLI (`swift test`) with **no Xcode GUI** once a working toolchain exists. This is where the bulk of test coverage lives (Swift Testing suites in `LedgerCore/Tests/`).
- **`PersonalLedger/`** — the iOS **app target** (SwiftUI views, the SwiftData `@Model`, `TransactionRepository`, `LogTransactionIntent`, settings). Requires Xcode to compile. Currently folder scaffold only; to be built in the Xcode phase.

The pivotal seam: **`LedgerCore.TransactionData` is the immutable domain value type that all logic operates on.** The SwiftData `@Model Transaction` (app target) is a persistence detail that maps *to/from* `TransactionData`. When adding behavior, put pure logic in `LedgerCore` against `TransactionData` and keep the `@Model` a thin mapper — do not push business rules into SwiftUI or the `@Model`.

## Domain invariants (do not break these)

These are encoded across `LedgerCore` and mandated by the RFC; violating them corrupts money data:

- **Money is `Decimal`, never `Double`.** Amount parsing/formatting goes through `Money`; never build a `Decimal` from a `Double` literal.
- **`amount` is stored positive; sign comes from `kind`.** Totals and CSV use `effectiveAmount` (`refund` → negative). A refund is only ever set via the expense/refund toggle — the amount parser rejects a typed minus sign.
- **A ledger is derived, not stored** — transactions grouped by `(year, month)` of `date` in the device calendar/timezone (`YearMonth` / `LedgerGrouping`). There is no Ledger table.
- **`category` is stored as a `String`** (not the `SpendingCategory` enum) for additive v2 migration; **`entryMethod` is never editable** after creation.
- **CSV** (`CSVExporter`) emits the *effective signed* amount and uses RFC 4180 quoting for free-text fields — see the exact column spec in RFC §FR-5.
- **`LogTransactionIntent` must stay in the app target** (not a separate extension). This keeps it in-process with the app's own SwiftData store, avoiding an App Group — which a **free** Apple team cannot provision. Do not add App Group capability while on the free team.

## Commands

Core logic (the only thing runnable without the Xcode app, once a working toolchain is present):

```bash
cd LedgerCore
swift build                                  # build the package
swift test                                   # run all Swift Testing suites
swift test --filter MoneyTests               # one suite
swift test --filter MoneyTests/parsesPlainDecimal   # one test
swiftc -parse Sources/LedgerCore/Money.swift # syntax-only check (works even with broken CLT)
```

App target (only after Xcode 26 is installed and the `.xcodeproj` exists):

```bash
xcodebuild -scheme PersonalLedger -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild -scheme PersonalLedger -destination 'platform=iOS Simulator,name=iPhone 15' test
xcrun devicectl device install app --device <UDID> <built.app>   # deploy to the physical iPhone
```

## Working conventions specific to this repo

- New pure logic ⇒ add a small file under `LedgerCore/Sources/LedgerCore/` **and** a Swift Testing suite under `LedgerCore/Tests/LedgerCoreTests/` (tests use the deterministic UTC `Calendar` and `dec()`/`day()`/`tx()` helpers in `TestSupport.swift`). Follow TDD.
- `LedgerCore` uses **Swift 6 language mode** (`swift-tools-version: 6.0`): a non-`Sendable` `static let` (e.g. a cached `NumberFormatter`/`DateFormatter`) is a compile error — mark intentionally-shared, never-mutated formatters `nonisolated(unsafe)`, or build them locally.
- Types consumed by the app target must be `public`.
