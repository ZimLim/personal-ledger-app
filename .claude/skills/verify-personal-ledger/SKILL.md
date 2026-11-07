---
name: verify-personal-ledger
description: Drive the Personal Ledger iOS app on a disposable simulator with Maestro and capture proof. Use to confirm a change to the ledger, add/edit/delete, month history, calendar, filter/sort, settings or card names works in the real app. Not for the physical iPhone or real Apple Pay.
---

# Verify Personal Ledger

The surface is a native iPhone app (SwiftUI and SwiftData). This skill builds it from the working tree, runs it on a simulator created for this run, taps through it with [Maestro](https://maestro.dev), and keeps the evidence.

Every command below runs from the repo root. `V` is the helper:

```bash
V=.claude/skills/verify-personal-ledger/bin/verify.sh
```

**Hard limits**

- Never drive the physical iPhone. It holds real spending data.
- Never drive the everyday `iPhone 17 Pro` simulator. The helper only targets the `PL-Verify-*` simulator it created.
- Don't use `xcodebuild test` or add to the test targets. The project owner asked for no new tests or test runs unless they request them. These flows live in this skill folder instead.

## Launch

First run on a machine, if `~/.maestro/bin/maestro` is missing:

```bash
curl -fsSL -o /tmp/maestro.zip https://github.com/mobile-dev-inc/maestro/releases/download/cli-2.12.0/maestro.zip
unzip -q /tmp/maestro.zip -d /tmp/maestro-unpacked && mv /tmp/maestro-unpacked/maestro ~/.maestro
```

Don't use `brew install --cask maestro`: that cask is an unrelated product. Don't use the `mobile-dev-inc/tap` formula here either: it wants unrelated Homebrew upgrades and a `sudo` Command Line Tools reinstall. Maestro needs Java 17+, and the build needs `xcodegen`. Both are installed.

Start an instance:

```bash
$V up
```

This creates a new iPhone 17 Pro simulator on iOS 26.5, waits for boot, then runs `scripts/deploy.sh sim` against it. It takes about 90 seconds. **Ready** means it prints `Ready. Evidence goes to: <path>` and `$V doctor` passes. The app starts empty, and there's no seed data: each flow creates what it needs through the UI.

Only one instance runs at a time, because `up` refuses while one exists. Your everyday simulators don't share its data. Two flows at once is untested, so run them one after another.

## Doctor

Run this first, and again whenever something looks off. It changes nothing.

```bash
$V doctor
```

It checks that the simulator is booted, the app is installed, the build matches the current sources, Maestro runs, and the evidence folder exists. If the build is stale, run `$V down` then `$V up`.

If `up` hangs on boot straight after an Xcode update, CoreSimulator is likely stuck. The known fix restarts the service for every simulator on the machine, so ask the owner before applying it.

## Drive

Reset before each flow, because every flow assumes an empty ledger:

```bash
$V reset
$V flow add-transaction
```

The available flows are in `flows/`, and [features/README.md](features/README.md) maps them to user journeys. Each takes one to three minutes. Read the map before driving, and add or extend a flow when a change isn't covered.

To write a new step, look at the live screen:

```bash
$V tree        # accessibility tree: labels, hints, values, enabled state
$V shot name   # screenshot into the evidence folder
```

Prefer these handles, all from the current app:

| Element | Handle |
| --- | --- |
| Add button on the ledger | `"Add Transaction"` |
| Toolbar | `"Ledger history"`, `"Filter and sort"`, `"Show calendar"` / `"Show list"` |
| Form fields, by placeholder | `"0.00"`, `"e.g. Village Grocer"`, `"e.g. Maybank debit, Cash"` |
| Form actions | `"Add"` or `"Save"`, `"Cancel"`, `"Refund"`, `"Date Picker"` |
| Date picker | id `DatePicker.PreviousMonth`, days as `".*, October 15"` |
| Calendar day | `"31 October, RM 42.50, today"` |
| Card mapping row | `"<card>, <source>"` as one element |

Maestro treats text as a regex that must match the whole label, so escape `?`, `(` and `)`. Use single-word test values, since autocorrect can change others. Enter amounts by tapping number pad keys, because `inputText` can lose digits in the amount field.

## Evidence

Everything goes to `docs/screenshots/<YYYY-MM-DD>/verify-<run>/`, the repo's durable screenshot location:

- `<flow>/maestro/<timestamp>/<flow>/takeScreenshot/*.png` holds the screenshots each flow names.
- `<flow>/maestro/<timestamp>/<flow>/commands.json` records every step and its status.
- `<flow>/run.log` and `<flow>/result.txt` record the output, exit code, simulator and build.
- `$V db <label>` saves the stored transactions to `db-<label>.txt`.
- `$V defaults <label>` saves the app's preferences, including card mappings, to `defaults-<label>.txt`.

Proof standards:

- Exercise the real user path, through the UI. Don't write to the database or use test-only hooks.
- Capture the action and the resulting state, not just the final screen.
- Confirm side effects. After a money change, run `$V db` and check the row: `amount` stays positive, and `kind` carries the sign.
- Confirm persistence with a relaunch. The flows do this with `stopApp` and `launchApp`.
- If a flow fails, find out why before re-running. A failed amount assertion may be a real app bug, so keep its evidence and report it. Don't retry until it passes. There's one open amount-entry bug already: see the [add-transaction gotchas](features/add-transaction.md#gotchas).
- Report what wasn't exercised. In particular, real Apple Pay auto-logging can't be proven here.

A failed flow keeps its 30+ MB simulator log for diagnosis, and a passing flow drops it. Evidence is left uncommitted. Don't commit a failed run's logs.

## Cleanup

```bash
$V down
```

This deletes only the simulator this run created. The evidence stays. Then confirm it survived:

```bash
ls docs/screenshots/$(date +%F)/
```

Run `down` after failed attempts too. It leaves Simulator.app open, and that's harmless.

## Helpers

`bin/verify.sh` is the only helper, and running it with no arguments prints its usage. Set `MAESTRO=<path>` if Maestro is installed somewhere else.
