#!/usr/bin/env bash
#
# run-e2e.sh — Run Kizba E2E integration tests against real pass + gpg.
#
# Creates an ephemeral GNUPGHOME, generates a short-lived key, runs the
# PassWriteIntegrationTests with KIZBA_E2E=1 and captures logs into
# .ai/build-log.md (on success) or .ai/build-errors.md (on failure).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LOG_TMP=""
GNUPGHOME_DIR=""

cleanup() {
  # best-effort kill and remove ephemeral GNUPGHOME/agents
  set +e
  if command -v gpgconf >/dev/null 2>&1; then
    gpgconf --kill all >/dev/null 2>&1 || true
  fi
  if [ -n "${GNUPGHOME_DIR:-}" ] && [ -d "$GNUPGHOME_DIR" ]; then
    rm -rf -- "$GNUPGHOME_DIR" || true
  fi
  set -e
}

trap cleanup EXIT

# --- Preconditions: required binaries ---
missing=0
for bin in pass gpg gpgconf xcodebuild git rg; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "ERROR: required binary '$bin' not found on PATH" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  cat > ".ai/build-errors.md" <<EOF
# E2E Preconditions failed

Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

Error: required binaries missing on PATH. Please install 'pass' and 'gpg' (eg. brew install pass gnupg) and ensure 'xcodebuild' is available.

This script checks for: pass, gpg, gpgconf, xcodebuild, git, rg
EOF
  echo "Wrote .ai/build-errors.md"
  exit 2
fi

echo "=== Versions ==="
pass --version 2>/dev/null || echo "pass version: unknown"
gpg --version | head -1
gpgconf --version || true
xcodebuild -version | head -1 || true
echo ""

# NOTE: Use a portable mktemp fallback for macOS where mktemp can
# sometimes fail with "File exists" when run concurrently. Attempt
# the system mktemp -d -t first, falling back to a pid+timestamp path
# and ensuring the directory exists. chmod 700 to restrict access.
# Create ephemeral GNUPGHOME
GNUPGHOME="$(mktemp -d -t kizba-e2e)" || GNUPGHOME="/tmp/kizba-e2e-$$-$(date +%s)"; mkdir -p "$GNUPGHOME"
GNUPGHOME_DIR="$GNUPGHOME"
export GNUPGHOME
chmod 700 "$GNUPGHOME"

# Ensure cleanup of agents and the ephemeral GNUPGHOME on EXIT
trap 'gpgconf --kill all >/dev/null 2>&1 || true; rm -rf "$GNUPGHOME"' EXIT

# configure gpg for non-interactive loopback pinentry
cat > "$GNUPGHOME/gpg-agent.conf" <<'GAG'
allow-loopback-pinentry
GAG

cat > "$GNUPGHOME/gpg.conf" <<'GCFG'
pinentry-mode loopback
batch
trust-model always
GCFG

# ensure fresh agent
gpgconf --kill all >/dev/null 2>&1 || true
# warm up
gpg --list-keys >/dev/null 2>&1 || true

# generate a short-lived key
cat > "$GNUPGHOME/gen-key" <<'KEY'
%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 2048
Name-Real: Kizba E2E
Name-Email: kizba-e2e@example.invalid
Expire-Date: 1d
%no-protection
%commit
KEY

gpg --batch --generate-key "$GNUPGHOME/gen-key" >/dev/null 2>&1 || true

# extract recipient id (first secret key long id)
RECIPIENT_ID="$(gpg --list-secret-keys --keyid-format LONG --with-colons 2>/dev/null | awk -F: '/^sec:/ {print $5; exit}')"

if [ -z "$RECIPIENT_ID" ]; then
  echo "WARNING: no secret key found in ephemeral GNUPGHOME" >&2
fi

# Run xcodebuild for the PassWriteIntegrationTests only
LOGFILE="${GNUPGHOME}/run-e2e-$(date +%s)-$$.log"
echo "Log file: $LOGFILE"

CMD=(xcodebuild test -scheme Kizba -project "$PROJECT_ROOT/Kizba.xcodeproj" -destination "platform=macOS" -only-testing:KizbaTests/PassWriteIntegrationTests)
echo "Running: KIZBA_E2E=1 ${CMD[*]}"

set +e
# ensure KIZBA_E2E is exported for xcodebuild/test runner visibility
export KIZBA_E2E=1
# run and capture
"${CMD[@]}" 2>&1 | tee "$LOGFILE"
EXIT_CODE=${PIPESTATUS[0]}
set -e

GIT_HEAD="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
NOW="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "E2E tests PASSED"
  {
    echo "# E2E Build Log"
    echo ""
    echo "Date: $NOW"
    echo "Exit code: 0"
    echo "Git HEAD: $GIT_HEAD"
    echo ""
    echo "## Command"
    echo ""
    echo '\'"'"'"'"
    printf 'KIZBA_E2E=1 %s\n' "${CMD[*]}"
    echo '\'"'"'"'"
    echo ""
    echo "## Versions"
    echo ""
    echo '```'
    pass --version 2>/dev/null || echo "pass version: unknown"
    gpg --version | head -1 || true
    echo '```'
    echo ""
    echo "## Summary"
    echo ""
    echo "All E2E tests passed."
    echo ""
    echo "Full log: $LOGFILE"
    echo ""
    echo "## Tail of xcodebuild output (last 500 lines)"
    echo ""
    echo '```'
    tail -500 "$LOGFILE" || true
    echo '```'
  } > "$PROJECT_ROOT/.ai/build-log.md"
  echo "Wrote $PROJECT_ROOT/.ai/build-log.md"
  EXIT_STATUS=0
else
  echo "E2E tests FAILED (exit code $EXIT_CODE)"
  {
    echo "# E2E Build Errors"
    echo ""
    echo "Date: $NOW"
    echo "Exit code: $EXIT_CODE"
    echo "Git HEAD: $GIT_HEAD"
    echo ""
    echo "## Command"
    echo ""
    echo '\'"'"'"'"
    printf 'KIZBA_E2E=1 %s\n' "${CMD[*]}"
    echo '\'"'"'"'"
    echo ""
    echo "## Versions"
    echo ""
    echo '```'
    pass --version 2>/dev/null || echo "pass version: unknown"
    gpg --version | head -1 || true
    echo '```'
    echo ""
    echo "## Failure output (last 500 lines)"
    echo ""
    echo '```'
    tail -500 "$LOGFILE" || true
    echo '```'
    echo ""
    echo "Full log: $LOGFILE"
  } > "$PROJECT_ROOT/.ai/build-errors.md"
  echo "Wrote $PROJECT_ROOT/.ai/build-errors.md"
  EXIT_STATUS=$EXIT_CODE
fi

exit $EXIT_STATUS
