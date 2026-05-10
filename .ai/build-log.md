Focused tests: KizbaTests/BiometricAuthenticatingTests

Command:
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/BiometricAuthenticatingTests

Result: PASSED — 3 tests, 0 failures

SourceGrepTests (no-local-auth import rule)

Command:
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests/testNoLocalAuthenticationImportInDomain

Result: PASSED — 0 tests (no matches), 0 failures

Full suite

Command:
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

Result: PASSED — 721 tests, 9 skipped, 0 failures
