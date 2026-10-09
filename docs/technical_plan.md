# Technical Plan — Personal Spending Tracker (iOS)

**Companion to:** [technical_rfc.md](./technical_rfc.md) (PRD v1.1)
**Author:** Hazim (plan drafted with Claude Code)
**Status:** Phase 1 (M1) and Phase 3 (M3) done — ledger, add/edit, delete, sidebar, plus the `Log Transaction` App Intent, setup guide and card mapping all build & run on the iOS 26.5 simulator; tests green (LedgerCore 85, app-target 19 unit + 3 UI). Phase 3 still needs its **on-device check** (a real Apple Pay tap — see Phase 3 below). Next: Phase 2 (CSV export), which was skipped over. Phase 6 (calendar view of daily totals) built 2026-10-10 — checked on the simulator, no tests yet (deferred by request).
**Deployment choice:** **Free personal team** (sideload via Xcode; ~7-day provisioning expiry accepted)
**Target:** iPhone 13 Pro, iOS 17+

---

## 0. Environment status (updated 2026-08-03)

| Check | Result | Action |
|---|---|---|
| Full Xcode.app | ✅ **Xcode 26.6 (17F113) installed & licensed** | — |
| Swift toolchain | ✅ Swift 6.3.3 (target `arm64-apple-macosx26.0`) | — |
| `LedgerCore` package | ✅ `swift build` clean, `swift test` **49/49 pass** | Verified core |
| iOS app `.xcodeproj` | ❌ Not created yet — `PersonalLedger/` is folders only | **Next: Phase 0.2** |

> **Remaining gap:** the app target can't be built until the `.xcodeproj` exists. The pure `LedgerCore` layer is done and fully tested from the CLI; the SwiftUI/SwiftData/App Intents code is the Xcode-phase work.

---

## 1. Architecture summary

Local-first, single-user. SwiftUI views → lightweight view models → `TransactionRepository` (protocol) → SwiftData `ModelContext`. A `LogTransactionIntent` (App Intent, **defined in the main app target**) writes to the same on-device store when triggered by a user-created Shortcuts "Transaction" automation.

```
SwiftUI Views ─ ViewModels ─ TransactionRepository ─ SwiftData (SQLite, app container)
                                        ▲
                              LogTransactionIntent  ◄── Shortcuts "Transaction" automation
                              (in app target, background, openAppWhenRun=false)
```

### 1.1 Key architectural decision — intent stays in the app target

Defining `LogTransactionIntent` inside the **main app target** (not a separate AppIntents extension) means the system background-launches the app's own process to run it, so the intent reads/writes the app's own SwiftData container. **No App Group container is required.** This is deliberate for the free-account path: App Groups generally require a paid Apple Developer membership. A separate extension + App Group is documented as a **v2** option only.

---

## 2. Module layout — pure core split from platform code

All framework-independent business logic lives in a standalone **Swift Package `LedgerCore`** (Foundation only). It builds and tests via `swift build` / `swift test` from the CLI with **no Xcode GUI required**, and the iOS app target depends on it. The SwiftData `@Model` maps to/from `LedgerCore.TransactionData`, so business rules stay unit-testable without SwiftData/SwiftUI.

```
LedgerCore/                          # Swift Package — pure logic (BUILT without Xcode GUI)
  Package.swift                      # swift-tools 6.0; platforms iOS 17 + macOS 13
  Sources/LedgerCore/
    TransactionKind / EntryMethod / SpendingCategory   # enums
    TransactionData.swift            # immutable domain value type (+ effectiveAmount)
    YearMonth.swift                  # (year,month) ledger identity, Comparable
    LedgerGrouping.swift             # group tx -> [LedgerMonth], newest first
    LedgerTotals.swift               # effective-amount sums (can be negative)
    MonthCalendar.swift              # one DayTotal per day of a month + grid offset (Phase 6)
    Money.swift                      # parse/validate/round + CSV number format
    MoneyFormatter.swift             # "RM 23.50" display formatting
    CSVExporter.swift                # RFC 4180 rows, filenames, sort-for-export
    DuplicateGuard.swift             # automation dedupe (amount+merchant, ±60s)
    CardSourceResolver.swift         # card name -> source label (§5.3), unmapped-card suggestions
    AutomationAmount.swift           # trigger amount text ("RM 23.50") -> Decimal
    AutomationLog.swift              # request -> log / skip duplicate / reject (pure decision)
    TransactionDraft.swift           # editable form state (value type)
    TransactionValidator.swift       # pure validation -> ValidatedDraft
  Tests/LedgerCoreTests/             # Swift Testing suites (bulk of coverage)

PersonalLedger/                      # iOS app target (NEEDS Xcode 26 to build)
  App/            PersonalLedgerApp.swift            # @main, ModelContainer wiring
  Models/         Transaction.swift                  # SwiftData @Model + <-> TransactionData mapper
  Persistence/    ModelContainerFactory, TransactionRepository (protocol + SwiftData impl)
  Features/
    Ledger/       LedgerView, LedgerViewModel, LedgerRowView, RunningTotalHeader, EmptyStateView,
                  LedgerCalendarView (Phase 6)
    AddEdit/      TransactionSheetView, TransactionFormViewModel (wraps TransactionDraft),
                  AmountField, RefundToggle, CategoryPicker, SourceChips
    Sidebar/      LedgerSidebarView, SidebarViewModel
    Automation/   LogTransactionIntent (thin wrapper), TransactionLogService, AutomationSetupView
    Settings/     SettingsView, CardMappingView, CardMappingFormView,
                  CardMappingStore (UserDefaults over CardSourceResolver)
  Shared/         DesignTokens.swift                 # greyscale semantic colors
PersonalLedgerUITests/               # critical-flow XCUITests
```

**Status:** every `LedgerCore` source + test file is written and **syntax-valid** (`swiftc -parse`). Full type-check and `swift test` are blocked only by the broken CLT toolchain — see §0; they run once Xcode 26 is installed. The app-target files above are the remaining scaffold for the Xcode phase (they need SwiftUI/SwiftData/AppIntents to compile).

---

## 3. Phased plan

### Phase 0 — Environment & scaffold `[LOW]`
- **0.1 (USER):** Install **Xcode 26** (iOS 26 device support) → `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` → `sudo xcodebuild -license accept`.
- **0.2:** Create Xcode project — iOS App, SwiftUI, SwiftData, min iOS 17, bundle id `com.hazim.personalledger`. Add unit + UI test targets. Add `LedgerCore` as a **local package dependency**.
- **0.3:** Verify the core first: `cd LedgerCore && swift test` (must pass) before writing any app-target code.
- **DONE:** `LedgerCore` package + full Swift Testing suite authored and syntax-checked (blocked from running only by the broken CLT — re-verify in 0.3).

### Phase 1 (M1) — Core `[HIGH]` — TDD, tests first
1. `Transaction` `@Model`: `Decimal amount`, `currencyCode="MYR"`, `kind`, `category` (String-backed), `entryMethod`, `date`, `merchant?`, `createdAt`. Computed **effectiveAmount** = `kind == .refund ? -amount : amount`.
2. `TransactionRepository` protocol + SwiftData impl (`findByMonth`, `create`, `update`, `delete`, `distinctSources`, `monthsWithTransactions`) — tested via **in-memory `ModelContainer`**.
3. `DateGrouping` — `(year, month)` bucketing in device calendar/timezone; future-dated + TZ edge tests.
4. `LedgerView` — pinned `RunningTotalHeader` (effective-sum, `.monospacedDigit()`), reverse-chron list, empty state, pinned full-width Add button.
5. Add/Edit sheet (shared FR-2/FR-7) — `TransactionFormViewModel` validation: amount > 0, minus rejected, 2dp cap, locale-separator normalize; refund toggle flips preview; category default Other; recent-source chips; Save enabled only when valid & changed.
6. Sidebar — year→month, current month always shown, per-month totals, select → reload.
7. Two-step delete — full-swipe **disabled** → Delete button → confirmation dialog; duplicated at bottom of edit sheet.

### Phase 2 (M2) — CSV export `[MEDIUM]`
- `CSVExporter` → exact §5 header/rows: **effective (signed) amount**, ISO-8601 date, 2dp, **RFC 4180 quoting** for merchant/source. Unit tests: quoting, refund sign, empty merchant, ordering.
- Per-month `spending-YYYY-MM.csv`; export-all `spending-all-YYYYMMDD.csv` (date-ascending). Toolbar + Settings entry points via `fileExporter`/share sheet.

### Phase 3 (M3) — App Intent + automation `[HIGH]` — **DONE 2026-10-08 (on-device check pending)**
- `TransactionLogService` (pure, testable) holds the write + **dedupe** logic; `LogTransactionIntent` is a thin wrapper (in app target, `openAppWhenRun=false`).
- Maps `card → source` via `CardMappingStore` (fallback `"Apple Pay – <card>"`); sets `entryMethod=.automation`, `category="Other"`, `kind=.expense`, `date=now`.
- **Dedupe guard:** reject matching `(amount, merchant, ±60s)` automation entry — unit-tested.
- `AutomationSetupView`: step-by-step guide + deep link to Shortcuts (iOS cannot install automations programmatically).

**As built:**
- The rules are split in two: the pure decision (`LedgerCore.AutomationLog.decide` → log / skip duplicate / reject) and the app-target `TransactionLogService`, which fetches the ±60s neighbours, applies the decision and saves. The intent only maps the decision to a result or an error.
- **Deviation from RFC §5.2:** the intent's `Amount` parameter is a `String`, not a `Double`. The trigger passes text with a currency symbol ("RM 23.50", "ARS 23,400.00"); `LedgerCore.AutomationAmount` parses it, so the amount stays `Decimal` end-to-end. Empty, zero, negative, multi-number or oddly separated text (".50", "23 50") is rejected and the run fails with a readable message instead of logging a guess.
- **One shared `ModelContainer`** (`ModelContainerFactory.shared`) serves both the UI scene and the intent, at SwiftData's default store location, so automation writes show up in a live `@Query` and existing data is untouched.
- Settings is reached from the foot of the history drawer: **Set up auto-logging** (the guide) and **Card names** (the mapping). Cards already logged under the fallback label are listed as one-tap suggestions, so the exact card name never has to be typed.
- Deep link is `shortcuts://create-automation` (opens the trigger list on iOS 26.5; falls back to `shortcuts://`). On iOS 26 the trigger is named **Wallet**; it was **Transaction** on iOS 17–18.

**Verified on the simulator:** the real intent run in-process against the live store (logs a row, skips the repeat, rejects a zero amount); Shortcuts lists the **Log Transaction** action; screenshots in `docs/screenshots/2026-10-08/`.
**Not verifiable without the phone:** the Wallet trigger itself, the exact text it passes for Amount/Merchant/Card, and the background launch when the app is not running.

### Phase 4 (M4) — Polish `[MEDIUM]`
- Greyscale `DesignTokens` (semantic light/dark), Dynamic Type, safe-area handling, accessibility labels, dedupe hardening.

### Phase 5 — Deploy to iPhone (free personal team) `[MEDIUM]`
1. iPhone → Settings → Privacy & Security → **Developer Mode → On** → restart.
2. Connect via USB → **Trust This Computer**.
3. Xcode → Settings → Accounts → add Apple ID (**Personal Team**).
4. Target → Signing & Capabilities → **Automatically manage signing**, select team, unique bundle id.
5. Select iPhone as destination → **Cmd+R** to build & install.
6. iPhone → Settings → General → VPN & Device Management → **trust** developer cert → launch.
7. Follow in-app setup guide to create the Shortcuts "Transaction" automation (**real device only** — Simulator has no Wallet/Apple Pay).
8. **Free-team upkeep:** the app stops launching after ~7 days; re-run from Xcode (**Cmd+R**) to refresh the provisioning profile. Upgrade to the paid Program later if weekly redeploys become annoying or TestFlight/OTA is wanted.

### Phase 6 — Calendar view (daily totals) `[MEDIUM]` — **BUILT 2026-10-10 (toggle tap and tests pending)**

A month calendar on the ledger screen showing what was spent on each day. This extends RFC v1.1 — it is not in the FR list. It is a per-day view of the month total the ledger already shows, and it stores nothing new.

**Behaviour:**
- A toggle button at the top right of the ledger screen (right of the filter/sort menu) swaps the transaction list for the calendar in place, and back. The pinned month header, running total, Add button and history drawer stay as they are. The app opens on the list.
- The calendar is a 7-column grid of **every day in the selected month**, under a weekday header. The week starts on the device calendar's first weekday.
- Each day shows the sum of that day's **effective amounts** (refunds subtract), so the days add up to the month total. A refund-only day is negative.
- A day with nothing logged shows `RM 0.00`, and that includes days still to come. A future-dated entry (RFC §8) counts on its own day.
- The payment-method filter applies to the calendar; sort has no effect on it.
- Display only: tapping a day does nothing in this pass.

**Pieces:**
- `LedgerCore/MonthCalendar.swift` — `MonthCalendar(month:transactions:calendar:)` gives one `DayTotal` (day, total) per day of the month plus `leadingBlanks` (the empty cells before day 1). `weekdaySymbols(calendar:)` gives the header in first-weekday order. Pure, built on `YearMonth` and `effectiveAmount`.
- `Features/Ledger/LedgerCalendarView.swift` — the grid. Amounts via `MoneyFormatter.displayEffective` with `.monospacedDigit()`, zero days in secondary grey, today outlined.
- `LedgerView` — a `showingCalendar` state and the toolbar toggle (`calendar` ↔ `list.bullet`).

**Tests:** deferred at the owner's request (2026-10-10). No unit or UI tests are written for this phase until asked; it is verified by a clean build and a manual check on the simulator.

**As built:**
- The weekday header and the day grid are two separate grids, and the day grid is a single `ForEach` over slots (blanks, then days). With three sibling `ForEach` blocks in one `LazyVGrid`, their overlapping integer IDs made the grid drop days 1–6.
- The weekday header uses short names ("Sun", "Mon", …).

**Verified on the simulator (iOS 26.5, October 2026):** all 31 days render, day 1 sits under Thursday, today is outlined, and the day cells (0.22 + 12.62 + 48.62) add up to the header's RM 61.46. Light and dark screenshots are in `docs/screenshots/2026-10-10/`.
**Not verified:** tapping the toggle (this session could not send taps to the simulator; the calendar screenshots came from a temporary build that opened on the calendar), a month with no transactions, a month under a payment-method filter, and a refund-only day.

---

## 4. Testing strategy (target 80% on the logic core)

- **Unit (bulk):** effectiveAmount, CSV export/quoting, amount parse/validate, `DateGrouping`, dedupe, repository (in-memory container), card mapping.
- **UI (XCUITest):** add → row appears + total updates; edit moves month; two-step delete; export sheet presents.
- **Reality note:** SwiftUI view bodies and the App Intent runtime path resist unit coverage; intent logic is factored into `TransactionLogService` so it *is* testable. 80% is targeted on the pure-logic core, not view code.

---

## 5. Risks

| Sev | Risk | Mitigation |
|---|---|---|
| HIGH | Full Xcode not installed (blocks all build/deploy) | Phase 0.1 — user installs |
| HIGH | Wallet "Transaction" trigger misses / not testable in Simulator | Accept per RFC §5.4; dedupe + manual entry fallback; test on device |
| MED | Free-team 7-day provisioning expiry | Re-run from Xcode weekly; upgrade to paid if needed |
| MED | SwiftData store access from background intent | Intent kept in app target → app's own container, no App Group |
| LOW | `Decimal`/locale money formatting | Covered by unit tests |

---

## 6. Immediate next actions

1. **USER:** Install **Xcode 26** (see §Phase 0.1) — the only remaining blocker.
2. **DONE:** `LedgerCore` Swift Package — 14 pure source files + full Swift Testing suite (8 test files) covering Money parsing, effective amounts, grouping/totals, CSV (RFC 4180) + filenames, dedupe, card mapping, and form validation. All syntax-checked; `swift test` pending a working toolchain.
3. **NEXT (after Xcode):** run `cd LedgerCore && swift test` to confirm the core is green, then create the `.xcodeproj`, add `LedgerCore` as a local dependency, and build the app-target scaffold (SwiftData `@Model` + mapper, repository, SwiftUI views, `LogTransactionIntent`).
