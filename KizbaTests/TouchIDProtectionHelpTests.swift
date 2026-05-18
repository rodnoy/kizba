import XCTest
@testable import Kizba

final class TouchIDProtectionHelpTests: XCTestCase {
    func testHelpCatalog_containsTouchIDProtectionTopic() {
        let topic = HelpCatalog.all.first(where: { $0.id == "touch-id-protection" })

        XCTAssertNotNil(topic)
        XCTAssertEqual(topic?.title, "Touch ID protection")
    }
}
