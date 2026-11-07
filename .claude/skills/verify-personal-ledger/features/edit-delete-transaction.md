# Edit and delete a transaction

The user taps a row to change it, or removes it by swiping or from inside the edit form. Deleting always asks for confirmation, and the running total follows every change.

## Sub-features

- `edit-save` changes an amount through the edit form.
- `delete-swipe` deletes by swiping a row, after confirmation.
- `delete-cancel` keeps the row when the dialog is cancelled.
- `delete-sheet` deletes from the edit form's `Delete Transaction` button.
- `delete-persist` keeps deleted rows gone after a relaunch.

## How to get to it (user POV)

- Tap a row in the ledger to open `Edit Transaction`.
- Swipe a row left to reveal `Delete`.
- Open a row and scroll to `Delete Transaction`.

## Driving it with Maestro

Preconditions:

- Baseline state from the [map](./README.md). The flow creates `Kopitiam` at RM 12.50 and `Tesco` at RM 7.00, so the total starts at `RM 19.50`.

Run everything below with `$V flow edit-delete-transaction`.

- **Open the form.** Tap `Kopitiam`. `Edit Transaction` appears, and `Save` is disabled until something changes.
- **Change the amount.** Tap `12.50`, erase it, and type `1800`. The field reads `18.00`.
- **Save it.** Tap `Save`. The row reads `RM 18.00`, and the total reads `RM 25.00`.
- **Cancel a delete.** Swipe `RM 7.00` left, tap `Delete`, and tap outside the `Delete this transaction?` dialog. The dialog closes, and `Tesco` stays.
- **Confirm a delete.** Repeat the swipe and tap the dialog's `Delete`. `Tesco` is gone, and the total reads `RM 18.00`.
- **Delete from the form.** Tap `Kopitiam`, dismiss the keyboard, scroll to `Delete Transaction`, and confirm. `No transactions yet this month` appears, and the total reads `RM 0.00`.
- **Proof.** The flow relaunches and the ledger is still empty. Run `$V db edit-delete` and expect no rows.

## Gotchas

- Swipe from the amount on the right. From the merchant label the swipe is too short and counts as a tap, which opens the edit form.
- The edit form opens with the number pad up, and that pad has its own `Delete` key. A tap on `Delete` then edits the amount instead of deleting. The symptom is `7.00` turning into `0.70` in the form.
- After a swipe, the dialog and the row both expose `Delete`. Select the dialog's with `below: "Delete this transaction\\?"`.
- On iOS 26 the row's delete dialog is a popover with only `Delete` and no `Cancel` button, so tapping outside it is the only way to cancel. Tap with `point: "50%,15%"`.
- Dismissing the dialog closes the swipe, so swipe again before the next `Delete`.
