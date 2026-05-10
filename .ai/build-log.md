FormFieldRow accessibility (D.3) verification

Commands executed:

1) xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/FormFieldRowAccessibilityTests
 - Result: 2 tests executed, 0 failures

2) xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests
 - Result: 19 tests executed, 0 failures

3) xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
 - Result: 718 tests executed, 9 skipped, 0 failures

4) rg -n '\\bas!\\b' Kizba
 - Result: no matches

5) rg -n 'Logger.*stdin|print\\(.*stdin' Kizba
 - Result: no matches

Summary: All focused tests and full test suite passed. No banned patterns found.
