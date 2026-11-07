# Auto-category

A new transaction takes the category last used at that merchant, so the user doesn't pick it again. It applies to manual entries and Apple Pay entries. A category the user picks by hand always wins, and editing an existing row never changes its category automatically.

## Sub-features

- `category-no-history` leaves a merchant with no history on `Other`.
- `category-full-name` matches only the full merchant name. A partial name stays on `Other`.
- `category-case` ignores upper and lower case.
- `category-chip` treats a recent-merchant chip the same as typing the name.
- `category-manual-wins` keeps a hand-picked category when the merchant changes afterwards.
- `category-chosen-other` counts a hand-picked `Other`, even when `Other` is already showing.
- `category-newest-row` follows the merchant's newest row, so fixing that row changes the next suggestion.
- `category-other-skipped` ignores rows saved as `Other`, so they don't teach the lookup.
- `category-edit-frozen` never changes the category of an existing row automatically.
- `category-apple-pay` applies the same lookup to entries saved by the `Log Transaction` action.

## How to get to it (user POV)

- Tap `Add Transaction`, then type a merchant into `e.g. Village Grocer`.
- Tap `Add Transaction`, then tap a recent-merchant chip under the merchant field.
- Tap an existing row to open `Edit Transaction`. The category should stay as it is here.
- Pay with Apple Pay on the phone, which runs the Shortcuts automation and its `Log Transaction` action. The flow below doesn't exercise this entry point. See the gotchas.

## Driving it with Maestro

Preconditions:

- Baseline state from the [map](./README.md), with an empty ledger.

Run everything below with `$V flow auto-category`. Every entry is RM 10.00, entered by `lib/start-form.yaml`.

- **Try a new merchant.** Type `Kopitiam` and press `Enter`. `Category, Other` is visible. Screenshot `01-no-history-stays-other`.
- **Teach it.** Tap `Category, Other`, then `Food`, then save with `lib/finish-form.yaml`. The `Kopitiam` row appears.
- **Type a partial name, then the full name.** Type `Kopi`, and `Category, Other` is visible. Add `tiam`, and `Category, Food` is visible. Screenshot `02-full-name-fills-food`. Erase one character, and `Category, Other` is visible again. Cancel.
- **Change the case.** Type `KOPITIAM`. `Category, Food` is visible. Cancel.
- **Tap a chip.** Tap the `Kopitiam` chip. `Category, Food` is visible. Screenshot `03-chip-fills-food`. Cancel.
- **Pick by hand, then change the merchant.** Type `Kopitiam`, pick `Health`, then replace the merchant with `Tesco`. `Category, Health` is visible. Screenshot `04-manual-pick-wins`. Cancel.
- **Choose `Other` on purpose.** With no merchant, tap `Category, Other` and select the `Other` menu item below `Travel`. Then type `Kopitiam`. `Category, Other` is visible. Screenshot `05-chosen-other-stays`. Cancel.
- **Fix the newest row.** Open the `Kopitiam` row, change it to `Groceries`, and tap `Save`. In a new form, type `Kopitiam`. `Category, Groceries` is visible. Screenshot `06-fix-changes-suggestion`. Save this entry.
- **Save a newer `Other` row.** Save `Grab` as `Travel`, then save `Grab` again with `Other` picked by hand. In a new form, type `Grab`. `Category, Travel` is visible. Screenshot `07-other-does-not-teach`. Cancel.
- **Edit a row.** Open a `Kopitiam` row, where `Category, Groceries` is visible. Replace the merchant with `Grab`. `Category, Groceries` is still visible. Screenshot `08-edit-does-not-follow`. Cancel.
- **Relaunch.** The flow stops and relaunches the app. The `Kopitiam` and `Grab` rows remain. Screenshot `09-after-relaunch`. This step only checks the rows, so the next step is what proves their categories.
- **Proof.** Run `$V db auto-category`. There are four rows, all amount `10`, kind `expense` and entry method `manual`, in this order: `Kopitiam` `Groceries`, `Kopitiam` `Groceries`, `Grab` `Travel`, `Grab` `Other`.

## Gotchas

- **Not verified by this flow:** the `Log Transaction` action. It's covered by one hand-driven run instead, using a hand-built shortcut in the simulator's Shortcuts app. Its steps relied on screen coordinates, so they weren't kept as a flow. That run saved `Kopitiam` as `Groceries`, `Tesco` as `Other` and a blank merchant as `Other`, and skipped an immediate repeat of the Tesco payment as a duplicate. The rows are in `docs/screenshots/2026-11-01/auto-category-simulator-run/db-shortcut.txt`. Don't report a pass of this flow as proof of the Apple Pay path.
- **Not proven anywhere yet:**
  - The real Wallet trigger, and how real Apple Pay merchant names match. Only a real payment on the phone can show this, and this skill must not drive the phone.
  - A blank-merchant payment when an earlier blank row has a real category. Only the guard in `CategorySuggester` covers it.
  - A failing history fetch, and the time the fetch takes.
- The number pad covers the category row and has no return key. Tap the merchant field, then `pressKey: Enter`, before tapping `Category, <value>`. The edit form opens with the pad up too.
- The picker row's label is `Category, <value>`. Assert on that to read the current category.
- Screenshots `02-full-name-fills-food` and `03-chip-fills-food` don't show the category, because the keyboard covers that row. For those two steps, the proof is the passing `Category, Food` assertion in `commands.json`. Maestro reads the label from the accessibility tree, so the assertion passes even though the row is hidden.
- With the menu open, `Other` also matches the row behind it. Select the menu item with `text: "Other"` and `below: "Travel"`.
- A screenshot straight after opening the menu can miss it. Assert a menu item is visible first.
- Enter the amount before tapping the merchant field.
- In one run, text typed into Merchant right after the form opened never appeared there. The likely cause is the amount field taking focus back as the sheet opens, but that isn't confirmed. If a merchant comes up empty, keep the evidence and report it.
