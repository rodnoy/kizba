import XCTest
@testable import Kizba

final class KeyValueEditorAccessibilityTests: XCTestCase {

    func testRowAccessibilityLabel_returnsOneIndexedString() {
        XCTAssertEqual(KeyValueEditor.rowAccessibilityLabel(index: 0), "Field row 1")
        XCTAssertEqual(KeyValueEditor.rowAccessibilityLabel(index: 1), "Field row 2")
        XCTAssertEqual(KeyValueEditor.rowAccessibilityLabel(index: 9), "Field row 10")
    }
}
