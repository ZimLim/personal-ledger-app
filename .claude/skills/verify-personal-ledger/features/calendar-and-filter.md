# Calendar and filter

The user views the month as a calendar of daily totals, narrows the ledger to one payment method, and re-sorts its rows. The running total and the calendar both follow the filter.

## Sub-features

- `calendar-toggle` switches between the list and the calendar.
- `calendar-today` shows today's total on today's cell.
- `filter-source` narrows rows and the total to one payment method.
- `filter-calendar` applies the same filter to the calendar.
- `filter-clear` restores everything with `All methods`.
- `sort-amount` reorders rows by amount.

## How to get to it (user POV)

- Tap the `Show calendar` or `Show list` button at the top right.
- Tap the `Filter and sort` button at the top right and choose from its menu.

## Driving it with Maestro

Preconditions:

- Baseline state from the [map](./README.md). The flow creates `Kopitiam` at RM 12.50 on `Cash` and `Grab` at RM 30.00 on `Card`, so the total starts at `RM 42.50`.

Run everything below with `$V flow calendar-and-filter`.

- **Open the calendar.** Tap `Show calendar`. Today's cell reads `RM 42.50`. Tap `Show list` to return.
- **Filter by method.** Tap `Filter and sort`, then `Card`. `Grab` stays, `Kopitiam` goes, and the total reads `RM 30.00`.
- **Check the filtered calendar.** Tap `Show calendar`. Today's cell reads `RM 30.00`. Tap `Show list`.
- **Clear the filter.** Tap `Filter and sort`, then `All methods`. `Kopitiam` returns, and the total reads `RM 42.50`.
- **Sort ascending.** Choose `Amount: low to high`. `Grab` is below `Kopitiam`.
- **Sort descending.** Choose `Amount: high to low`. `Kopitiam` is below `Grab`.
- **Proof.** Screenshots `01` to `06` in the flow's `takeScreenshot` folder show each state. These views don't change stored data.

## Gotchas

- A calendar cell is one accessibility element, so its day and amount aren't separate labels. Match it with a regex such as `".*RM 42\\.50, today"`.
- The calendar flow asserts on today's cell, so entries must be dated today. An entry on another day needs a different label.
