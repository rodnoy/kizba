LocalAuthBiometricAuthenticator (E.2)

Focused tests: KizbaTests/LocalAuthBiometricAuthenticatorTests
Command:
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/LocalAuthBiometricAuthenticatorTests

Result: PASSED — 3 tests, 0 failures

Notes:
- Mapping helpers exercised via unit tests. No evaluatePolicy system UI invoked in CI.
- Minor compiler warnings unrelated to the new files observed during full-suite runs; focused tests passed.
