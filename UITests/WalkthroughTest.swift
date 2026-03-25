import XCTest

final class WalkthroughTest: XCTestCase {
    @MainActor let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = true
        app.launchArguments += ["-hasCompletedOnboarding", "true"]
        app.launch()
    }

    func testFullWalkthrough() throws {
        // 1. Home screen loads
        sleep(2)
        XCTAssertTrue(app.tabBars.buttons["Today"].exists, "Today tab should exist")

        // 2. Navigate to Calendar
        app.tabBars.buttons["Calendar"].tap()
        sleep(1)

        // 3. Navigate to Stats
        app.tabBars.buttons["Stats"].tap()
        sleep(1)

        // 4. Navigate to Settings
        app.tabBars.buttons["Settings"].tap()
        sleep(1)

        // 5. Back to Home
        app.tabBars.buttons["Today"].tap()
        sleep(1)
    }
}
