# Running the App — Simulator & Physical iPhone

How to build, run, and iterate on the Personal Ledger app. The simulator path works
today with zero setup; the physical-iPhone path needs a **one-time signing setup**
(free Apple account, no $99 needed). Status when this was written: **postponed** — the
device path has not been done yet.

> One-command entry point for everything below: [`scripts/deploy.sh`](../scripts/deploy.sh).

---

## TL;DR

```bash
# Simulator (no signing, works now)
./scripts/deploy.sh sim
./scripts/deploy.sh sim --shot          # also saves a screenshot under docs/screenshots/<date>/

# Physical iPhone (after the one-time signing setup below)
DEVELOPMENT_TEAM=<your-team-id> ./scripts/deploy.sh device
```

The script always runs `xcodegen generate` first, so the project matches source.

---

## Prerequisites (already installed on this machine)

| Tool | Why | Install |
|---|---|---|
| **Xcode 26 or later** | iOS 26 device support (the phone runs iOS 26) | Mac App Store |
| **XcodeGen** | generates `PersonalLedger.xcodeproj` from `project.yml` | `brew install xcodegen` |
| **iOS simulator runtime** | needed to build/run in the Simulator | `xcodebuild -downloadPlatform iOS` (~7 GB, one-time) |

`LedgerCore` (the pure logic) needs none of this — it runs with `cd LedgerCore && swift test`.

---

## Run on the simulator (no signing)

```bash
./scripts/deploy.sh sim
```

This regenerates the project, boots the default simulator (`iPhone 17 Pro`), builds
unsigned, installs, and launches. Override the device with `SIMULATOR="iPhone 17" ./scripts/deploy.sh sim`.

The Simulator window is a **fully interactive iOS** — tap through the app there to feel
the UX; you don't need screenshots for that. `--shot` just saves a frame for the record.

---

## Run on your physical iPhone

### Step 1 — Device prep (one-time, on the iPhone)

1. **Settings → Privacy & Security → Developer Mode → On** → restart the phone.
2. Connect by USB → unlock → tap **Trust This Computer**.

### Step 2 — Signing setup (one-time, in Xcode)

You currently have **no signing identity**, so this step also creates your free
development certificate.

1. **Add your Apple ID** — Xcode → **Settings (⌘,) → Accounts → “+” → Apple ID**. A free
   **“Personal Team”** appears (no card, no $99).
2. **Enable automatic signing** — `open PersonalLedger.xcodeproj` → select the
   **PersonalLedger** target → **Signing & Capabilities** → tick **Automatically manage
   signing** → set **Team** to your Personal Team. This mints your **Apple Development
   certificate** into the keychain. (A signing warning until a device is attached is normal.)
3. **Find your Team ID** (10 characters) — Xcode → Settings → Accounts → select your team.
   Or: `xcodebuild -showBuildSettings -scheme PersonalLedger | grep DEVELOPMENT_TEAM`.

### Step 3 — Deploy

```bash
DEVELOPMENT_TEAM=<your-team-id> ./scripts/deploy.sh device
```

(Optionally bake the Team ID into [`project.yml`](../project.yml) under the app target's
`settings.base.DEVELOPMENT_TEAM` so you can just run `./scripts/deploy.sh device`.)

### Step 4 — Trust the app (first launch only)

iPhone → **Settings → General → VPN & Device Management** → tap your developer cert →
**Trust**. Then open the app.

### The free-team catch

The provisioning profile **expires after ~7 days** — when the app stops launching, just
run `./scripts/deploy.sh device` again to refresh it. (A paid Apple Developer Program
account removes this and unlocks TestFlight; not needed for personal use.)

---

## Why signing is passed on the command line (XcodeGen note)

`xcodegen generate` **rewrites the project from `project.yml` on every run**, which would
wipe any signing settings clicked in the Xcode GUI. So `deploy.sh` passes
`DEVELOPMENT_TEAM` + `-allowProvisioningUpdates` on the command line instead. What
persists across regenerates:

- the **certificate** → lives in your **keychain** (created once by the GUI step);
- the **provisioning profile** → auto-created/refreshed per build by `-allowProvisioningUpdates`.

So the Xcode GUI is needed **only once** — to create the cert and reveal the Team ID.

---

## Fast iteration (what to use when)

| Speed | Tool | Use for |
|---|---|---|
| Instant | **SwiftUI Previews** (Xcode canvas; "Preview on Device" runs on the phone) | designing/tweaking individual screens |
| Seconds | **Simulator** (`deploy.sh sim`) | clicking through whole flows |
| ~30s | **`deploy.sh device`** | real-hardware feel; the only way to test Apple Pay / Shortcuts (FR-4) |

There is **no Expo equivalent** for native iOS: apps are signed native binaries, so there's
no "push your code into a pre-signed container" path. Closest options: SwiftUI Previews
(official), Swift Playgrounds app (on-device authoring, no Mac), or InjectionIII (3rd-party
hot reload). TestFlight is Apple's OTA beta channel but needs the paid account.

---

## Troubleshooting

- **`No connected iPhone`** → do Step 1 (USB, unlock, Trust, Developer Mode on).
- **`You have not agreed to the Xcode license`** (appears after an Xcode update) →
  `sudo xcodebuild -license accept`.
- **Simulator hangs on "Waiting on System App"** (common after a *major* Xcode update) →
  `xcrun simctl shutdown all; killall -9 com.apple.CoreSimulator.CoreSimulatorService; xcrun simctl erase "iPhone 17 Pro"`, then boot again (first boot runs a ~40s data migration).
- **Signing error / no profile on device build** → confirm Step 2 was done (cert exists:
  `security find-identity -v -p codesigning` should list an "Apple Development" identity)
  and that `DEVELOPMENT_TEAM` is correct.
