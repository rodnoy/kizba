SourceGrepTests — failing logs (excerpt)

Failure: KizbaTests.SourceGrepTests.testNoModelConstructorInSheetBody

Reason: Found model constructor invocations inside sheet/popover/fullScreenCover bodies.
Offending snippet:
Kizba/Presentation/SourceGrepFixtures/SheetInitViolation.swift:10: MyModel()

Full failing assertion text (xcodebuild excerpt):
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/SourceGrepTests.swift:504: error: -[KizbaTests.SourceGrepTests testNoModelConstructorInSheetBody] : failed - Found model constructor invocations inside sheet/popover/fullScreenCover bodies. Move model construction out of the closure (use @State/@StateObject or create the model outside) or add `// kizba:allow-sheet-init` to opt-out with justification.

Context: The test scans Presentation sources for any `SomethingModel()` calls inside SwiftUI presentation closure bodies. The fixture `Kizba/Presentation/SourceGrepFixtures/SheetInitViolation.swift` intentionally contains such a call to validate the rule; fix options:
- Move the model construction out of the closure (preferred for production code).
- Add `// kizba:allow-sheet-init` at top of file with justifying comment if this instance is intentionally allowed.

No other test failures reported.
