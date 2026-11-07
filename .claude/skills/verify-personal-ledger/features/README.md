# Personal Ledger verification map

This directory is the maintained source for verifying the user-facing behavior of Personal Ledger. Read the index before driving the app, then use the matching feature file as the recipe.

## Baseline preconditions

- `$V` is `.claude/skills/verify-personal-ledger/bin/verify.sh`, run from the repo root.
- `$V up` has created a `PL-Verify-*` simulator, and `$V doctor` passes.
- `$V reset` has run, so the ledger is empty and no card names are saved.
- Never drive an instance that this verification run didn't start, and never the physical iPhone.

## Driving conventions

- Start every recipe from the baseline state.
- Prefer accessibility labels and field placeholders over coordinates.
- Treat every quoted label as literal. Maestro reads it as a regex over the whole label.
- Dismiss the keyboard with `pressKey: Enter` before tapping anything low on the form.
- Enter amounts by tapping number pad keys one at a time, never with `inputText`. See the [add-transaction gotchas](./add-transaction.md#gotchas).

## Proof and skip reporting

- Capture the user action and the resulting state with `takeScreenshot`, not only the final screen.
- Mutation proof includes a second read: `$V db <label>` or `$V defaults <label>`, plus a relaunch.
- Record the feature and entry point used with every artifact.
- Report an unreachable path with the attempted command and the unmet precondition.
- Don't report a skipped entry point as verified through a different path.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph describing the user-visible behavior. It then uses exactly four H2 sections in this order.

1. `Sub-features` lists short IDs with one line for each behavior.
2. `How to get to it (user POV)` lists every user entry point.
3. `Driving it with Maestro` starts with `Preconditions:` and uses labeled bullets that pair each user action with an exact command and observable result.
4. `Gotchas` lists traps that can waste or invalidate a verification run.

## Features

- [Add a transaction](./add-transaction.md) covers expenses, refunds, validation, cancelling and persistence.
- [Edit and delete a transaction](./edit-delete-transaction.md) covers row editing and both delete paths.
- [Month history](./month-history.md) covers past-dated entries, the drawer, and switching months.
- [Calendar and filter](./calendar-and-filter.md) covers the calendar toggle, payment-method filter and sorting.
- [Settings and card names](./settings-card-names.md) covers the auto-logging guide and card mappings, and lists what the simulator can't prove about Apple Pay.
- [Auto-category](./auto-category.md) covers filling in a new entry's category from the merchant's history, and lists what isn't proven for Apple Pay entries.

## Not in the map yet

- CSV export. The plan's Phase 2 isn't built, and the app has no export UI.
