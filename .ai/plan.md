# Goal

Verify and complete Task B.5 "OTP setting + Help topic". The feature is already implemented; one small gap remains: `HelpCatalog` lacks a `public static var oneTimePasswords` accessor (the other 4 topics have one). Add it and a corresponding test assertion.

# Constraints

- Minimal, non-invasive changes.
- Follow existing accessor pattern (guard-let over `all`, fallback to builder).
- Branch: `feat/b5-otp-setting-help-topic`
- Commit message: `feat(help): add HelpCatalog.oneTimePasswords accessor`

# Tasks

## Task 1
- Objective: Add `public static var oneTimePasswords: HelpTopic` accessor to `HelpCatalog`
- Files to modify: `Kizba/Presentation/Features/Help/HelpCatalog.swift`
- Implementation: After line 79 (after `configurePinentry` accessor), add:
  ```swift
  /// First-class accessor for the one-time passwords topic.
  public static var oneTimePasswords: HelpTopic {
      guard let topic = all.first(where: { $0.id == "one-time-passwords" }) else {
          return Self.makeOneTimePasswords()
      }
      return topic
  }
  ```
- Verification: Project compiles (`xcodebuild build -scheme Kizba`).
- Risks: None.

## Task 2
- Objective: Add test assertion for the new accessor in `HelpCatalogTests`
- Files to modify: `KizbaTests/HelpCatalogTests.swift`
- Implementation: In `testSetupTopics_haveAccessors()` (line 159), append:
  ```swift
  XCTAssertEqual(HelpCatalog.oneTimePasswords.id, "one-time-passwords")
  ```
  Also update the arrays in `testSetupTopics_haveExpectedSectionCount` and similar tests that enumerate topics (lines 167+) to include `HelpCatalog.oneTimePasswords` if the other accessors are listed there.
- Verification: `xcodebuild test -scheme Kizba -only-testing KizbaTests/HelpCatalogTests` passes.
- Risks: None.

## Task 3
- Objective: Verify existing OTP setting tests pass
- Files to modify: None
- Verification: `xcodebuild test -scheme Kizba -only-testing KizbaTests/SettingsModelTests/testShowOTP_defaultIsTrue -only-testing KizbaTests/SettingsModelTests/testShowOTP_persists -only-testing KizbaTests/SettingsModelTests/testReset_restoresShowOTPDefault -only-testing KizbaTests/SettingsModelTests/testHasChanges_flipsWhenShowOTPMutated`
- Risks: None — these already pass.

# Suggested current step

Task 1 + Task 2 together (single commit). Task 3 is verification-only.
