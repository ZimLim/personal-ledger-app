# Technical PRD — Personal Spending Tracker (iOS)

**Version:** 1.1 (adds refunds, categories, running total, export-all, safer deletes)
**Author:** Hazim
**Status:** Draft
**Target device:** iPhone 13 Pro (iOS 17+)
**Distribution:** Personal use only (sideload via Xcode, or personal TestFlight/Developer account)

---

## 1. Overview

A single-user iOS app for logging and reviewing personal spending. Transactions are organized into monthly ledgers. Entries can be added manually via a modal, or automatically via iOS Shortcuts automation triggered by Apple Pay transactions. Any month's ledger can be exported as CSV to the Files app.

### 1.1 Goals

- Frictionless manual transaction entry (< 5 seconds per entry)
- Zero-touch logging of Apple Pay transactions via iOS automation
- Fast month-by-month review of spending history
- Full data ownership: local-first storage, CSV export

### 1.2 Non-goals

- Multi-user support, accounts, or authentication
- Cloud sync / backend server
- Budgeting, analytics, or charts. Categories are *captured* (see FR-2), but reporting/insights on them are future scope.
- Android or web support

---

## 2. Platform & Architecture Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Platform | Native iOS, Swift + SwiftUI | Requirement 4 (Apple Pay automation) requires App Intents, which rules out a PWA/web app. SwiftUI is the fastest path for a simple UI. |
| Min iOS version | iOS 17 | Required for modern App Intents and SwiftData. iPhone 13 Pro supports iOS 17+. |
| Persistence | SwiftData (local, on-device) | Single user, no sync needed. SwiftData gives model-driven persistence with minimal boilerplate. Backed by SQLite. |
| Automation bridge | App Intents framework + iOS Shortcuts "Transaction" automation | The only supported mechanism for reacting to Apple Pay/Wallet transactions. See §5. |
| Export | `FileExporter` / `UIActivityViewController` (share sheet) | Native way to save a generated CSV to Files or share it. |
| Backend | None | All data on-device. |

### 2.1 High-level architecture

```
┌─────────────────────────────────────────────┐
│                    App                      │
│  SwiftUI Views ── ViewModels ── SwiftData   │
│        ▲                          ▲         │
│        │                          │         │
│  App Intents (LogTransactionIntent)         │
└────────▲────────────────────────────────────┘
         │ invoked by
┌────────┴────────────────────────────────────┐
│ iOS Shortcuts Automation                    │
│ Trigger: "Transaction" (Wallet/Apple Pay)   │
│ Passes: amount, merchant, card              │
└─────────────────────────────────────────────┘
```

---

## 3. Data Model

### 3.1 `Transaction` (SwiftData `@Model`)

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `id` | UUID | PK, auto-generated | |
| `amount` | Decimal | Required, > 0 | Store as `Decimal`, never `Double` (money). Currency assumed MYR; store `currencyCode: String` defaulting to `"MYR"` for future-proofing. |
| `source` | String | Required | Where the money comes from, e.g. "Maybank debit", "Apple Pay – BigPay card", "Cash". Free text with recent-values suggestions. |
| `date` | Date | Required, defaults to `now` | Transaction date. Only the day component is significant for ledger grouping. |
| `merchant` | String? | Optional | Free-text description, e.g. "Village Grocer". |
| `kind` | Enum (`expense`, `refund`) | Required, default `expense` | `amount` is always stored **positive**; `kind` determines its sign in totals and export. Set via an explicit "Refund" toggle in the modal — the user never types a negative number. |
| `category` | String | Required, default `"Other"` | Single-select from the category list (see §3.3). Stored as string for forward-compatibility with user-defined categories. |
| `entryMethod` | Enum (`manual`, `automation`) | Required, default `manual` | Distinguishes hand-entered vs Apple Pay–automated entries. |
| `createdAt` | Date | Auto-set | Audit field. |

**Effective amount** (used everywhere sums appear): `kind == .refund ? -amount : amount`.

### 3.2 Ledger

A **ledger is not a stored entity**. It is a derived grouping: transactions bucketed by `(year, month)` of `date`, computed via SwiftData predicates. This avoids sync/consistency issues between a Ledger table and its transactions.

### 3.3 Categories

Fixed v1 list (single selection): **Food, Groceries, Transport/Gas, Entertainment, Shopping, Bills & Utilities, Health, Travel, Other**. Automation-logged entries default to `Other` (the Shortcuts Transaction trigger does not reliably supply a category) and can be recategorized by tapping the row. A user-editable category list is a v2 candidate; storing `category` as a string keeps that migration additive.

---

## 4. Functional Requirements

### FR-1: Landing page — current month ledger

- On launch, display the current calendar month's ledger.
- **Header:** month name + year (e.g. "August 2026") with a **running total** pinned at the top of the page: the sum of effective amounts (expenses minus refunds) for the viewed month. It stays visible while the list scrolls (pinned header) and updates immediately on add/edit/delete. Refund-heavy months can show a negative total.
- **List:** transactions in reverse-chronological order. Each row shows: effective amount (prominent; refunds rendered with a minus sign and a small "Refund" tag), merchant (or "—" if empty), category, source, and day of month.
- **Empty state:** simple message ("No transactions yet this month").
- **Footer:** full-width, screen-wide **"Add Transaction"** button pinned to the bottom safe area, always visible (list scrolls beneath it).
- Row interactions: tap to edit (FR-7); delete per FR-6.

### FR-2: Add Transaction modal

- Tapping "Add Transaction" presents a sheet (`.sheet`, medium/large detent).
- Fields, in order:
  1. **Amount** — required. Decimal pad keyboard, auto-focused on open. Validate > 0 (always entered as a positive number).
  2. **Expense / Refund toggle** — explicit segmented control, defaulting to **Expense**. Selecting **Refund** sets `kind = .refund`; the amount preview flips to negative so the effect is obvious. This is the *only* way to record a negative value — the amount field itself rejects minus signs.
  3. **Category** — required. Single-selection dropdown (`Picker`, menu style) over the §3.3 list, defaulting to "Other".
  4. **Source** — required. Text field with quick-pick chips of recently used sources (derived from existing data, no separate table).
  5. **Date** — optional. Compact `DatePicker`, pre-filled with today. If untouched, today's date is used.
  6. **Merchant description** — optional. Free text.
- **Save** is disabled until amount and source are valid. **Cancel** dismisses without saving.
- On save: persist, dismiss, and the ledger list updates immediately (if the date falls in the currently viewed month).

### FR-3: Collapsible sidebar — ledger history

- A sidebar/drawer toggled by a hamburger/sidebar icon in the top-left of the landing page.
- Implementation: slide-over drawer (custom or `NavigationSplitView` collapsed behavior) — on iPhone this presents as an overlay panel, dismissible by tapping outside or swiping.
- **Content:** months grouped by year, newest first:
  ```
  2026
    August (current)
    July
    June
  2025
    December
    ...
  ```
- Only months that contain ≥ 1 transaction are listed (plus the current month, always).
- Each row shows month name + total spend for that month.
- Selecting a month replaces the main ledger view with that month's ledger. The "Add Transaction" button remains available (new entries default to today's date regardless of the viewed month).

### FR-4: Apple Pay auto-logging (iOS automation)

See §5 for the full design. Summary of behavior:

- The app exposes a **"Log Transaction"** App Intent accepting `amount`, `merchant`, and `card` parameters.
- The user configures a **Shortcuts personal automation** with the **Transaction** trigger (Wallet), set to "Run Immediately", which passes the transaction's amount, merchant name, and card into the intent.
- The intent writes a `Transaction` with `entryMethod = .automation`, `source` = card name (mapped, see §5.3), `merchant` = merchant name, `date` = now, `kind` = `expense`, `category` = `"Other"` (recategorize by tapping the row).
- The app includes an in-app **setup guide screen** with step-by-step instructions (and a button deep-linking to the Shortcuts app), since the automation must be created manually by the user — iOS does not allow apps to install automations programmatically.

### FR-5: CSV export

- Entry points:
  - **Export month** — toolbar action on the ledger screen; exports the currently viewed month as `spending-YYYY-MM.csv`.
  - **Export all** — button in Settings (and in the same toolbar menu); exports every transaction across all months as `spending-all-YYYYMMDD.csv`, sorted by date ascending.
- Format (both exports share it):
  ```csv
  date,amount,currency,type,category,source,merchant,entry_method
  2026-08-01,23.50,MYR,expense,Groceries,Apple Pay – BigPay card,Village Grocer,automation
  2026-08-01,8.00,MYR,expense,Food,Cash,,manual
  2026-08-02,-23.50,MYR,refund,Groceries,Apple Pay – BigPay card,Village Grocer,manual
  ```
- The `amount` column carries the **effective (signed)** value so the CSV sums correctly in any spreadsheet; `type` makes refunds filterable.
- Field rules: dates in ISO 8601 (`YYYY-MM-DD`); amounts with 2 decimal places, no thousands separators; RFC 4180 quoting/escaping for free-text fields (merchant, source).
- Presented via the iOS share sheet / `fileExporter`, allowing "Save to Files" (satisfies "save to the phone") or AirDrop/share.

### FR-6: Two-step row deletion

- Deletion must always take **two deliberate taps** so a single mis-tap can never destroy data:
  1. Swipe left on a row (full-swipe-to-delete is **disabled**) to reveal a **Delete** button — tap it (tap 1).
  2. A confirmation dialog appears: "Delete this transaction? RM 23.50 · Village Grocer" with **Delete** (destructive) / **Cancel** — tap Delete (tap 2).
- The same two-step Delete is available at the bottom of the edit sheet (Delete → confirm), for users who don't discover swipe.
- No undo mechanism in v1; the confirmation dialog is the safety net.

### FR-7: Edit transaction

- Tapping any row opens the same sheet as FR-2, pre-filled with the row's values (amount, Expense/Refund toggle state, category, source, date, merchant).
- All fields are editable, including automation-logged entries (the common case: recategorizing from "Other" or fixing the source mapping).
- Same validation as FR-2; the primary button reads **Save** and is enabled only when something changed. Cancel discards.
- Changing the date to a different month moves the transaction to that month's ledger; if it leaves the currently viewed month, it disappears from the list and both months' totals update.
- `entryMethod` is never editable — it stays `automation`/`manual` as originally recorded, so you can always tell how an entry got in.
- The two-step Delete (FR-6) sits at the bottom of this sheet.

---

## 5. Apple Pay Automation — Technical Design

### 5.1 Constraint

iOS provides **no API** for apps to read Wallet/Apple Pay transaction history directly (that is restricted to card issuers via FinanceKit, which requires special entitlement). The supported path for third-party/personal apps is:

> **Shortcuts personal automation → "Transaction" trigger → runs a shortcut → calls an App Intent exposed by this app.**

### 5.2 App Intent spec

```swift
struct LogTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Transaction"
    static let openAppWhenRun: Bool = false   // runs in background

    @Parameter(title: "Amount")   var amount: Double
    @Parameter(title: "Merchant") var merchant: String?
    @Parameter(title: "Card")     var card: String?

    func perform() async throws -> some IntentResult { ... }
}
```

- `openAppWhenRun = false` so logging is silent/background.
- The intent writes to the shared SwiftData store. If the intent runs in an extension process, the store must live in an **App Group container** so both the app and the intent extension can access it.
- Idempotency guard: reject/merge if an identical `(amount, merchant, ±60s)` automation entry already exists, to protect against duplicate trigger fires.

### 5.3 Card → Source mapping

The Transaction trigger provides the card's display name (e.g. "BigPay Visa"). The app keeps a small user-editable mapping (Settings screen) from card name → preferred `source` label. Unmapped cards fall back to `"Apple Pay – <card name>"`.

### 5.4 Known limitations (accepted)

- Automation must be set up manually once per device (and per card, if scoping triggers to specific cards).
- The trigger fires for Apple Pay/Wallet transactions only — physical-card and online non-Apple-Pay purchases still need manual entry.
- Refunds/reversals are not signaled; corrections are manual.
- Trigger reliability depends on iOS delivering the Wallet notification; occasional misses are possible.

---

## 6. UI / Design Spec

### 6.1 Visual language — minimal greyscale

- **Palette:** pure greyscale only. Suggested tokens:
  - Background: `#FFFFFF` (light) / `#000000` (dark)
  - Primary text: `#111111` / `#F2F2F2`
  - Secondary text: `#6E6E6E`
  - Dividers/borders: `#E5E5E5` / `#2C2C2C`
  - Primary button: `#111111` fill, white label (inverted in dark mode)
- Support both light and dark mode via semantic colors.
- No accent colors, no icons beyond SF Symbols in monochrome, no shadows beyond subtle elevation on the modal/drawer.
- Typography: system SF Pro; amounts in `.monospacedDigit()` for column alignment.

### 6.2 UX principles

- One primary action per screen (the Add button).
- Amount field auto-focused with decimal keyboard — an entry should take 3 taps + typing.
- No confirmation dialogs anywhere **except** deletion, which is deliberately two-step (FR-6).
- Respect Dynamic Type and safe areas (Face ID notch, home indicator).

---

## 7. Screens Inventory

| # | Screen | Purpose |
|---|---|---|
| 1 | Ledger (landing) | Current/selected month's transactions, total, Add button |
| 2 | Add/Edit Transaction sheet | FR-2 fields |
| 3 | Sidebar drawer | Year-grouped month list |
| 4 | Automation setup guide | Step-by-step Shortcuts instructions + card mapping |
| 5 | Settings (minimal) | Card→source mapping, export shortcuts, app info |

---

## 8. Edge Cases & Rules

- **Timezone:** ledger bucketing uses the device's current calendar/timezone.
- **Future-dated entries:** allowed; they appear in the corresponding future month's ledger.
- **Deleting the last transaction of a past month:** the month disappears from the sidebar.
- **Amount input:** normalize locale decimal separators; cap at 2 decimal places; minus sign rejected (refunds only via the toggle).
- **Refund totals:** monthly running total and export sums use effective amounts; a month can legitimately total negative.
- **Automation entries with missing merchant:** merchant stays empty; still valid.
- **Storage migration:** SwiftData schema versioning from v1; additive changes only where possible.

---

## 9. Milestones

| Phase | Scope |
|---|---|
| M1 | Data model (incl. kind + category), ledger view with running total, add/edit-transaction sheet (refund toggle, category picker), month navigation (sidebar), two-step delete |
| M2 | CSV export: per-month + export-all via share sheet |
| M3 | App Intent + App Group store + automation setup guide + card mapping |
| M4 | Polish: dark mode, Dynamic Type, dedupe guard |

---

## 10. Resolved Decisions

1. **Refunds:** supported as negative *effective* values, entered only via an explicit Expense/Refund toggle in the modal — never by typing a minus sign. (v1.1)
2. **Currency:** MYR-only for v1; `currencyCode` field kept for future-proofing. Foreign-currency Apple Pay transactions log the amount as passed by the Shortcut, assumed MYR.
3. **Backup:** iCloud device backup covers app data implicitly; **Export all** (FR-5) is the explicit safety net.