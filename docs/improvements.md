# Improvements — Running Wishlist

A running backlog of improvements and ideas for the Personal Ledger app. Drop anything
here as it comes up — polish, UX tweaks, new ideas, nice-to-haves.

This is intentionally **separate** from:
- [technical_plan.md](technical_plan.md) — the planned, phased build (M1–M4)
- [technical_rfc.md](technical_rfc.md) — the product spec / source of truth

> **Status:** 🔵 idea · 🟡 planned · 🟢 done · ⚪️ parked
> **Priority:** P1 (soon) · P2 (eventually) · P3 (someday)

| # | Improvement | Area | Priority | Status | Added | Notes |
|---|---|---|---|---|---|---|
| 1 | Filter & sort on the main ledger — filter by **payment method** (source) | UI / query | P3 | 🟢 done | 2026-10-06 | Toolbar filter/sort menu via `LedgerQuery` (tested). Done 2026-10-07. |
| 2 | "Add Transaction" button should look clickable — **brighter when idle** | UI / greyscale (RFC §6.1) | P3 | 🟢 done | 2026-10-06 | Explicit near-black/white tokens in `PrimaryButtonStyle`. Done 2026-10-07. |
| 3 | **Cents-first** amount input (type digits, fills from the right: 5→0.05, 500→5.00) | UI / input | P3 | 🟢 done | 2026-10-06 | `CentsAmount` (tested) + `.onChange` reformat. ⚠️ live-reformat can drop digits under *very* fast input; fine for normal typing — harden with a `UITextField` if it bites. Done 2026-10-07. |
| 4 | Integrate **Supabase** as the data store | Architecture / data | P3 | ⚪️ parked | 2026-10-06 | **Parked 2026-10-06 — staying local-first (SwiftData).** Filter/sort (#1) are done locally, no backend needed. Revisit only if cloud **sync / multi-device / web access / server backup** becomes a goal; that would be an RFC change. |
| 5 | Deleting is buggy — swipe **"Delete" label/icon renders wrong** and deletion feels unreliable | UI / list | P1 | 🟢 done | 2026-10-06 | Two fixes: (a) replaced row-as-`Button` with `onTapGesture` (reliability); (b) the real visual bug — the view's `.tint(.primary)` cascaded into the swipe action, turning the destructive button **white in dark mode** so its white trash icon was invisible. Fixed with an explicit `Color.destructiveSwipe` grey tint on the Delete button. Done 2026-10-07. |
| 6 | **Merchant required** + remembers recent merchants (like Source); move it **between the amount card and Category** | UI / form | P1 | 🟢 done | 2026-10-06 | Required in `TransactionValidator`; `SuggestionChips` for recents; own section below the amount card. Overrides RFC §3.1 for manual entry. Done 2026-10-07. |

## How to use this file

- **Add a row** for each idea — one line is fine; detail in Notes.
- Move items to 🟡 **planned** when they get scheduled (and note the phase), 🟢 **done** when shipped (link the commit).
- Keep genuinely-scheduled work in `technical_plan.md`; this file is the open wishlist that feeds it.
- Tell Claude "add an improvement: …" and it'll append a row here.
