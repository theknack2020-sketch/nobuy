import XCTest

final class NoBuyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        // Main tab should show "Bugün" tab
        XCTAssertTrue(app.tabBars.buttons["Bugün"].exists)
        XCTAssertTrue(app.tabBars.buttons["Takvim"].exists)
        XCTAssertTrue(app.tabBars.buttons["Ayarlar"].exists)
    }
}
