// Fixture: allow-list — file contains allow-list comment and should be skipped
// kizba:allow-sheet-init
// This fixture is allow-listed and should be skipped by the test scanner.
// kizba:allow-sheet-init

final class AllowedModel {}

let sheetAllowedSnippet = """
.sheet {
    AllowedModel()
}
"""
