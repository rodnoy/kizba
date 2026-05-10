import XCTest
import SwiftUI
@testable import Kizba

final class FormFieldRowAccessibilityTests: XCTestCase {
    func testShouldUseVerticalLayout_returnsFalseForDefaultSize() {
        let standard: [DynamicTypeSize] = [
            .xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge
        ]

        for size in standard {
            XCTAssertFalse(
                FormFieldRow<EmptyView>.shouldUseVerticalLayout(size),
                "\(size) should use horizontal layout"
            )
        }
    }

    func testShouldUseVerticalLayout_returnsTrueForAccessibilitySize() {
        let accessibility: [DynamicTypeSize] = [
            .accessibility1, .accessibility2, .accessibility3,
            .accessibility4, .accessibility5
        ]

        for size in accessibility {
            XCTAssertTrue(
                FormFieldRow<EmptyView>.shouldUseVerticalLayout(size),
                "\(size) should use vertical layout"
            )
        }
    }
}
