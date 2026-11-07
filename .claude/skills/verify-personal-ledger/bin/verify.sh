#!/usr/bin/env bash
#
# Drives Personal Ledger on a disposable iOS simulator for verification.
#
#   verify.sh up                  # create a simulator, build, install, launch
#   verify.sh doctor              # read-only: is this instance worth driving?
#   verify.sh reset               # reinstall the app, emptying its data
#   verify.sh flow <name>         # run flows/<name>.yaml and keep its evidence
#   verify.sh db <label>          # save the stored transactions as evidence
#   verify.sh defaults <label>    # save the app's UserDefaults as evidence
#   verify.sh shot <label>        # save a screenshot as evidence
#   verify.sh tree                # print the live accessibility tree
#   verify.sh down                # delete the simulator; evidence stays
#
# Only ever targets the simulator this script created. It never touches the
# physical iPhone or the everyday "iPhone 17 Pro" simulator.
set -euo pipefail

BUNDLE_ID="com.hazim.personalledger"
SIM_PREFIX="PL-Verify-"
DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-26-5"
MAESTRO="${MAESTRO:-$HOME/.maestro/bin/maestro}"
APPLE_EPOCH_OFFSET=978307200

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"
STATE_FILE="${TMPDIR:-/tmp}/personal-ledger-verify/current.env"

export MAESTRO_CLI_NO_ANALYTICS=1 MAESTRO_CLI_NO_UPDATE_CHECK=1

log() { printf '▶ %s\n' "$*"; }
die() { printf '✗ %s\n' "$*" >&2; exit 1; }

load_state() {
  [[ -f "$STATE_FILE" ]] || die "No verification instance. Run: verify.sh up"
  # shellcheck disable=SC1090
  source "$STATE_FILE"
  [[ "$SIM_NAME" == "$SIM_PREFIX"* ]] || die "Refusing to drive '$SIM_NAME': not a $SIM_PREFIX simulator."
}

# Identifies the app sources a build came from, committed or not.
build_stamp() {
  {
    git -C "$ROOT" rev-parse HEAD
    git -C "$ROOT" status --porcelain -- PersonalLedger LedgerCore project.yml
    git -C "$ROOT" diff HEAD -- PersonalLedger LedgerCore project.yml
  } | shasum -a 256 | awk '{print $1}'
}

app_data_dir() { xcrun simctl get_app_container "$SIM_UDID" "$BUNDLE_ID" data; }
app_bundle_dir() { xcrun simctl get_app_container "$SIM_UDID" "$BUNDLE_ID" app; }

cmd_up() {
  [[ ! -f "$STATE_FILE" ]] || die "An instance already exists. Run: verify.sh down"
  [[ -x "$MAESTRO" ]] || die "Maestro not found at $MAESTRO. See the skill's Launch section."

  local run_id sim_name udid evidence stamp
  run_id="$(date +%H%M%S)"
  sim_name="$SIM_PREFIX$run_id"
  evidence="$ROOT/docs/screenshots/$(date +%F)/verify-$run_id"
  stamp="$(build_stamp)"

  log "Creating simulator $sim_name"
  udid="$(xcrun simctl create "$sim_name" "$DEVICE_TYPE" "$RUNTIME")"
  mkdir -p "$(dirname "$STATE_FILE")" "$evidence"
  printf 'SIM_NAME=%q\nSIM_UDID=%q\nEVIDENCE=%q\nBUILD_STAMP=%q\n' \
    "$sim_name" "$udid" "$evidence" "$stamp" > "$STATE_FILE"

  log "Waiting for it to boot"
  xcrun simctl bootstatus "$udid" -b >/dev/null
  log "Building and installing with scripts/deploy.sh"
  SIMULATOR="$sim_name" "$ROOT/scripts/deploy.sh" sim

  log "Ready. Evidence goes to: $evidence"
}

cmd_doctor() {
  load_state
  local failed=0 state app_ok
  check() { if [[ "$2" == "ok" ]]; then printf 'ok    %s\n' "$1"; else printf 'FAIL  %s: %s\n' "$1" "$2"; failed=1; fi; }

  state="$(xcrun simctl list devices | awk -v id="$SIM_UDID" 'index($0,id){print}' | sed -E 's/.*\((Booted|Shutdown|[A-Za-z ]+)\) *$/\1/')"
  check "simulator $SIM_NAME ($SIM_UDID) is booted" "$([[ "$state" == "Booted" ]] && echo ok || echo "state is '${state:-missing}'")"
  app_ok="$(app_data_dir >/dev/null 2>&1 && echo ok || echo "not installed; run verify.sh reset")"
  check "$BUNDLE_ID is installed" "$app_ok"
  check "build matches the current sources" "$([[ "$(build_stamp)" == "$BUILD_STAMP" ]] && echo ok || echo "sources changed; run verify.sh down, then up")"
  check "maestro $("$MAESTRO" --version 2>/dev/null | tail -1) runs" "$([[ -x "$MAESTRO" ]] && echo ok || echo "missing at $MAESTRO")"
  check "evidence directory exists ($EVIDENCE)" "$([[ -d "$EVIDENCE" ]] && echo ok || echo missing)"
  [[ "$failed" -eq 0 ]] || die "Instance is not worth driving."
}

cmd_reset() {
  load_state
  local staged
  staged="$(mktemp -d)/PersonalLedger.app"
  cp -R "$(app_bundle_dir)" "$staged"
  xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl uninstall "$SIM_UDID" "$BUNDLE_ID"
  xcrun simctl install "$SIM_UDID" "$staged"
  rm -rf "$(dirname "$staged")"
  log "App reinstalled with empty data."
}

cmd_flow() {
  load_state
  local name="${1:?Usage: verify.sh flow <name>}" flow out status=0
  flow="$SKILL_DIR/flows/$name.yaml"
  [[ -f "$flow" ]] || die "No flow at $flow"
  out="$EVIDENCE/$name"
  mkdir -p "$out"

  # The flows read month names from these, so they keep working month to month.
  "$MAESTRO" --no-ansi --udid="$SIM_UDID" test \
    --test-output-dir "$out/maestro" \
    -e "THIS_MONTH=$(date +%B)" \
    -e "THIS_YEAR=$(date +%Y)" \
    -e "LAST_MONTH=$(date -v-1m +%B)" \
    -e "LAST_MONTH_YEAR=$(date -v-1m +%Y)" \
    "$flow" 2>&1 | tee "$out/run.log" || status=$?

  printf 'flow=%s\nexit=%s\nsimulator=%s\nbuild=%s\n' "$name" "$status" "$SIM_UDID" "$BUILD_STAMP" > "$out/result.txt"
  [[ "$status" -eq 0 ]] || die "Flow $name failed (exit $status). Evidence: $out"

  # The simulator log runs to tens of MB. It only helps diagnose a failure.
  find "$out/maestro" -name device-simulator.log -delete
  log "Flow $name passed. Evidence: $out"
}

cmd_db() {
  load_state
  local label="${1:?Usage: verify.sh db <label>}" store out
  store="$(app_data_dir)/Library/Application Support/default.store"
  [[ -f "$store" ]] || die "No store yet at $store. Launch the app first."
  out="$EVIDENCE/db-$label.txt"
  sqlite3 -readonly -header -column "$store" \
    "SELECT ZMERCHANT AS merchant, ZAMOUNT AS amount, ZKINDRAW AS kind, ZCATEGORY AS category, ZSOURCE AS source,
            ZENTRYMETHODRAW AS entry_method, date(ZDATE + $APPLE_EPOCH_OFFSET, 'unixepoch', 'localtime') AS date
     FROM ZTRANSACTION ORDER BY ZDATE;" | tee "$out"
  log "Saved $out"
}

cmd_defaults() {
  load_state
  local label="${1:?Usage: verify.sh defaults <label>}" plist out
  # The app's preferences live in its own container, not the simulator's global domain.
  plist="$(app_data_dir)/Library/Preferences/$BUNDLE_ID.plist"
  [[ -f "$plist" ]] || die "No preferences yet at $plist. The app flushes them when it stops."
  out="$EVIDENCE/defaults-$label.txt"
  plutil -p "$plist" | tee "$out"
  log "Saved $out"
}

cmd_shot() {
  load_state
  local out="$EVIDENCE/${1:?Usage: verify.sh shot <label>}.png"
  xcrun simctl io "$SIM_UDID" screenshot "$out" >/dev/null 2>&1
  log "Saved $out"
}

cmd_tree() {
  load_state
  "$MAESTRO" --no-ansi --udid="$SIM_UDID" hierarchy --compact
}

cmd_down() {
  load_state
  xcrun simctl shutdown "$SIM_UDID" 2>/dev/null || true
  xcrun simctl delete "$SIM_UDID"
  rm -f "$STATE_FILE"
  log "Deleted $SIM_NAME. Evidence kept at: $EVIDENCE"
}

case "${1:-}" in
  up|doctor|reset|flow|db|defaults|shot|tree|down) command="$1"; shift; "cmd_$command" "$@" ;;
  *) sed -n '3,14p' "$0"; exit 1 ;;
esac
