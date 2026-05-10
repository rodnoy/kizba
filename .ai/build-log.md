Command: 
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SecretRevealFieldTouchIDTests
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/EntryDetailModelBiometricRevealTests
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

Git HEAD: 1f80b2f21e7943144df83bcd4c2574b512dda3bb

Result: Full test suite passed — 735 tests executed, 9 skipped, 0 failures.

Notes: EntryDetailView now passes biometricAuthenticator: nil and gateEnabled: false to SecretRevealField to avoid duplicate biometric prompts; model-level gating (EntryDetailModel.requestReveal) remains the single auth path.
