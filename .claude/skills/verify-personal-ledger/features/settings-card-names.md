# Settings and card names

The user opens Settings from the history drawer, reads the Apple Pay auto-logging guide, and maps card names to the source label they want logged. Mappings survive a relaunch.

## Sub-features

- `settings-open` reaches Settings from the drawer.
- `automation-guide` shows the auto-logging steps and the `Open Shortcuts` button.
- `card-validate` keeps `Save` disabled until both fields are filled.
- `card-add` saves a mapping.
- `card-delete` removes a mapping by swiping.
- `card-persist` keeps mappings after a relaunch.

## How to get to it (user POV)

- Tap `Ledger history`, then `Settings` at the foot of the drawer.
- From Settings, tap `Set up auto-logging` or `Card names`.

## Driving it with Maestro

Preconditions:

- Baseline state from the [map](./README.md), with no card names saved.

Run everything below with `$V flow settings-card-names`.

- **Open Settings.** Tap `Ledger history`, then `Settings`. `Apple Pay` is visible.
- **Read the guide.** Tap `Set up auto-logging`. `Open Shortcuts` and `Steps` are visible. Tap `Settings` to go back.
- **Check validation.** Tap `Card names`, then `Add Card`. `Save` is disabled.
- **Add and remove a card.** Save `OldCard` as `OldSource`, swipe its row left, and tap `Delete`. The row is gone.
- **Add the card that stays.** Save `BigPayVisa` as `BigPay`. The row reads `BigPayVisa, BigPay`.
- **Confirm persistence.** The flow relaunches and returns to `Card names`. The row is still there, and `OldCard` isn't.
- **Proof.** Run `$V defaults settings`. `cardSourceMapping` holds `BigPayVisa` mapped to `BigPay`, and nothing for `OldCard`.

## Gotchas

- **Not verified here:** the `Open Shortcuts` button's hand-off, the `Log Transaction` intent, and the real Wallet trigger. Those need a real Apple Pay tap on the phone, which this skill must not drive. Report them as unverified, and never claim card mapping proves auto-logging works.
- `e.g. BigPay` and `e.g. BigPay Visa` are different fields. Matching is on the whole label, so each selects only its own.
- The row is one accessibility element, `<card>, <source>`. The source alone isn't a usable selector.
- `$V defaults` reads the app's preferences file, which the app may not have written until it stops. Run it after the flow's relaunch.
