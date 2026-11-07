# Add a transaction

The user logs an expense or refund from the ledger's Add button. The new row appears in the current month, the running total updates, and the entry survives a relaunch.

## Sub-features

- `add-validate` keeps `Add` disabled until the form is valid.
- `add-expense` saves an expense with cents-first amount entry, so `1250` reads as `12.50`.
- `add-refund` saves a refund shown as negative, which lowers the total.
- `add-cancel` discards an unfinished draft.
- `add-persist` keeps saved rows after a relaunch.

## How to get to it (user POV)

- Tap the `Add Transaction` button pinned to the bottom of the ledger.

## Driving it with Maestro

Preconditions:

- Baseline state from the [map](./README.md), with an empty ledger.

Run everything below with `$V flow add-transaction`.

- **Check validation.** Tap `Add Transaction`. `Add` is visible and disabled.
- **Enter an expense.** Type `1250` into `0.00`, `Kopitiam` into `e.g. Village Grocer`, and `Cash` into `e.g. Maybank debit, Cash`. `Recorded as RM 12.50` appears.
- **Save it.** Tap `Add`. The `Kopitiam` row appears, and the total reads `RM 12.50`.
- **Enter a refund.** Add `250` with `Refund` selected and merchant `Tesco`. The preview reads `Recorded as -RM 2.50`, the row shows `-RM 2.50` with a `Refund` tag, and the total reads `RM 10.00`.
- **Cancel a draft.** Open the form, type `Discarded`, and tap `Cancel`. No `Discarded` row appears.
- **Confirm persistence.** The flow stops and relaunches the app. Both rows and `RM 10.00` remain.
- **Proof.** Run `$V db add-transaction`. `Kopitiam` has amount `12.5` and kind `expense`, and `Tesco` has amount `2.5` and kind `refund`, both with entry method `manual`.

## Gotchas

- The Source field sits behind the keyboard while Merchant is focused, so a tap on it lands on a key. Press `Enter` first. The symptom is a merchant like `KopitiamYCash` and an `Add` button that stays disabled.
- **Open app bug, seen twice on 2026-10-31.** With Maestro's fast `inputText`, typed `1250` was saved as `RM 1.25`, and typed `3000` left the field stuck on `3.000` with `Add` disabled. It's intermittent: a dedicated probe saw 0 in 19 fast attempts. The likely cause is the amount field's `onChange` rewriting the text while the next digit arrives, but that isn't confirmed. Whether it can happen at human typing speed is unknown.
- So flows tap the number pad key by key, which had 0 failures in 19 attempts. Don't switch amounts back to `inputText` to save time. To reproduce the bug on purpose, use `inputText` and repeat it.
- If `Recorded as RM …` fails even with key taps, that's new and important. Keep the evidence and report it. Don't retry until it passes.
- `RM 12.50` can match both the row and the total. Use a total that differs from every row when the total is what you're proving.
