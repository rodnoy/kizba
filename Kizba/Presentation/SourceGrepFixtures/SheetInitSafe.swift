// Fixture: safe pattern — model created outside the sheet closure
// This fixture demonstrates the safe pattern: model created outside
// the closure. The test scanner should NOT flag this file.

final class SafeModel {}

let sheetSafeSnippet = """
.sheet(isPresented: .constant(true)) {
    Text("Safe")
}
"""
