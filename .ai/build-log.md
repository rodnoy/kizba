Build and test run for step 8.1

xcodebuild -project Kizba.xcodeproj -scheme Kizba -destination 'platform=macOS' test

Partial xcodebuild output captured during automated run. Tests started; compilation
warnings regarding actor isolation are present. No failing tests specific to the
UserDefaultsSettingsStore were reported before output truncation.
