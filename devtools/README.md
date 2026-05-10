Run Kizba E2E integration tests

Prerequisites:
- pass (>= 1.7.4)
- gpg (>= 2.2, 2.5.19 recommended)
- gpgconf (bundled with gnupg)
- Xcode (xcodebuild available)

Usage:

  ./devtools/run-e2e.sh

To run a single test (insert+show round-trip):

  ./devtools/run-e2e.sh --single

The script creates an ephemeral GNUPGHOME under /tmp, generates a short-lived GPG key, runs the PassWriteIntegrationTests with KIZBA_E2E=1 and writes a concise log to .ai/build-log.md on success or .ai/build-errors.md on failure.
