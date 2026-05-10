// Fixture: violation — constructing model inside sheet closure
// This fixture intentionally contains a sheet closure with a Model() call
// to trigger the SourceGrepTests rule.

final class MyModel {}

let sheetViolationSnippet = """
.sheet {
    // This should be flagged by SourceGrepTests
    MyModel()
}
"""
