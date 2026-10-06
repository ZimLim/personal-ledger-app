#!/usr/bin/env bash
#
# One-command deploy for the Personal Ledger app.
#
#   ./scripts/deploy.sh sim            # build + install + launch on the simulator
#   ./scripts/deploy.sh sim --shot     # ...and save a screenshot under docs/screenshots/<date>/
#   DEVELOPMENT_TEAM=XXXXXXXXXX ./scripts/deploy.sh device   # deploy to a connected iPhone
#
# Regenerates the Xcode project from project.yml first, so it always matches source.
# The device path needs a one-time signing setup in Xcode (see README / CLAUDE.md).
set -euo pipefail

SCHEME="PersonalLedger"
BUNDLE_ID="com.hazim.personalledger"
CONFIG="Debug"
SIMULATOR="${SIMULATOR:-iPhone 17 Pro}"
TARGET="${1:-sim}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

log()  { printf "\033[1;34m▶ %s\033[0m\n" "$*"; }
err()  { printf "\033[1;31m✗ %s\033[0m\n" "$*" >&2; }

command -v xcodegen >/dev/null || { err "xcodegen not found — run: brew install xcodegen"; exit 1; }

log "Regenerating Xcode project from project.yml"
xcodegen generate >/dev/null

# Resolve the built .app path for a given -destination.
app_path() {
  local settings dir name
  settings="$(xcodebuild -scheme "$SCHEME" -configuration "$CONFIG" -destination "$1" \
                -showBuildSettings CODE_SIGNING_ALLOWED=NO 2>/dev/null)"
  dir="$(echo "$settings"  | awk -F' = ' '/ TARGET_BUILD_DIR =/{print $2; exit}')"
  name="$(echo "$settings" | awk -F' = ' '/ FULL_PRODUCT_NAME =/{print $2; exit}')"
  echo "$dir/$name"
}

case "$TARGET" in
  sim)
    log "Booting simulator: $SIMULATOR"
    xcrun simctl boot "$SIMULATOR" 2>/dev/null || true
    open -a Simulator 2>/dev/null || open "$(xcode-select -p)/Applications/Simulator.app" 2>/dev/null || true

    log "Building (simulator, unsigned)"
    xcodebuild -scheme "$SCHEME" -configuration "$CONFIG" \
      -destination "platform=iOS Simulator,name=$SIMULATOR" \
      build CODE_SIGNING_ALLOWED=NO >/dev/null

    APP="$(app_path "platform=iOS Simulator,name=$SIMULATOR")"
    log "Installing: $APP"
    xcrun simctl install "$SIMULATOR" "$APP"
    log "Launching $BUNDLE_ID"
    xcrun simctl launch "$SIMULATOR" "$BUNDLE_ID" >/dev/null

    if [[ "${2:-}" == "--shot" ]]; then
      DAY="$(date +%F)"; OUT="docs/screenshots/$DAY/$(date +%H%M%S).png"
      mkdir -p "docs/screenshots/$DAY"
      xcrun simctl io "$SIMULATOR" screenshot "$OUT" >/dev/null 2>&1
      log "Saved screenshot: $OUT"
    fi
    ;;

  device)
    : "${DEVELOPMENT_TEAM:?Set your 10-char Team ID, e.g.  DEVELOPMENT_TEAM=ABCDE12345 ./scripts/deploy.sh device  (find it in Xcode > Settings > Accounts > your team).}"

    log "Finding a connected iPhone"
    UDID="${DEVICE_UDID:-}"
    if [[ -z "$UDID" ]]; then
      UDID="$(xcrun devicectl list devices 2>/dev/null \
        | awk 'tolower($0) ~ /physical/ && tolower($0) !~ /simulated/ {
            for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}$/ || $i ~ /^[0-9A-Fa-f]{40}$/) { print $i; exit }
          }')"
    fi
    [[ -n "$UDID" ]] || { err "No connected iPhone. Plug in via USB, unlock, tap Trust, and enable Developer Mode (Settings > Privacy & Security). You can also pass DEVICE_UDID=<udid>."; exit 1; }
    log "Device UDID: $UDID"

    log "Building + signing (team $DEVELOPMENT_TEAM)"
    xcodebuild -scheme "$SCHEME" -configuration "$CONFIG" -destination "id=$UDID" \
      -allowProvisioningUpdates \
      DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" CODE_SIGN_STYLE=Automatic \
      build >/dev/null

    APP="$(app_path "id=$UDID")"
    log "Installing to device: $APP"
    xcrun devicectl device install app --device "$UDID" "$APP"
    log "Launching on device"
    LERR="$(mktemp)"
    if ! xcrun devicectl device process launch --device "$UDID" "$BUNDLE_ID" 2>"$LERR"; then
      if grep -qiE "not been explicitly trusted|invalid code signature" "$LERR"; then
        err "Installed OK, but iOS needs you to TRUST this developer once before it can launch:"
        err "  iPhone → Settings → General → VPN & Device Management → Developer App → tap your Apple ID → Trust"
        err "Then tap the app icon on the phone, or re-run this command."
      else
        cat "$LERR" >&2
      fi
      rm -f "$LERR"; exit 0
    fi
    rm -f "$LERR"
    ;;

  *)
    err "Usage: $0 [sim|device] [--shot]"; exit 1 ;;
esac

log "Done ✔"
