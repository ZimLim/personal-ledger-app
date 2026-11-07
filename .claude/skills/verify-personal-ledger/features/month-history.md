# Month history

The user dates an entry in an earlier month and browses past ledgers from the history drawer. Each month has its own rows and total, and the current month is always listed.

## Sub-features

- `history-date` files an entry under the month its date falls in.
- `history-drawer` lists months with their totals and marks the current one.
- `history-switch` changes the ledger to the chosen month and closes the drawer.

## How to get to it (user POV)

- Tap `Date Picker` in the add or edit form to choose another date.
- Tap the `Ledger history` button at the top left to open the `Ledgers` drawer.

## Driving it with Maestro

Preconditions:

- Baseline state from the [map](./README.md). `$V flow` supplies this month's and last month's names.

Run everything below with `$V flow month-history`.

- **Add this month's entry.** The flow adds `Kopitiam` at RM 12.50.
- **Date an entry last month.** Fill in `Grab` at RM 30.00, tap `Date Picker`, tap id `DatePicker.PreviousMonth`, and tap `".*, ${LAST_MONTH} 15"`. Close the popup, then tap `Add`.
- **Check this month.** The header still shows this month, `Kopitiam` is listed, `Grab` isn't, and the total reads `RM 12.50`.
- **Open the drawer.** Tap `Ledger history`. `Ledgers`, `(current)`, both month names and `RM 30.00` are visible.
- **Switch months.** Tap last month's name. The drawer closes, the header shows last month, `Grab` and `Day 15` are visible, and `Kopitiam` isn't.
- **Switch back.** Open the drawer and tap this month. `Kopitiam` returns.
- **Proof.** Run `$V db month-history`. `Grab` is dated the 15th of last month.

## Gotchas

- Close the date popup by tapping near the top of the screen. The dismiss region covers the whole screen, and a tap at its centre can land on the calendar.
- Month names come from `$V flow`, so running a flow file directly with Maestro leaves them unset.
- This only covers one month back. Year boundaries haven't been driven.
