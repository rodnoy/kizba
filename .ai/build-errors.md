xcodebuild test failed (step 8.3)

Summary:
- Command: xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
- Result: BUILD FAILED, tests not run (build failed)

Relevant error (concise):
- Swift compiler error in Kizba/Presentation/Features/Settings/SettingsView.swift: unable to resolve module dependency 'PlaygroundSupport'
  import PlaygroundSupport
  note: A dependency of main module 'Kizba'

Effect:
- Build and test run aborted. Fix or remove the PlaygroundSupport import (or add appropriate dependency) in SettingsView.swift to resolve.

Full xcodebuild output is available in the local machine's DerivedData xcresult bundle.
