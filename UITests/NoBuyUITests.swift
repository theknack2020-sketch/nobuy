import XCTest

final class NoBuyUITests: XCTestCase {
    @MainActor let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["-hasCompletedOnboarding", "true"]
        app.launch()
    }

    func testTabBarExists() throws {
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.exists, "Today tab should exist")
    }

    func testNavigateToSettings() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        settingsTab.tap()
        sleep(1)
    }

    func testNavigateToCalendar() throws {
        app.tabBars.buttons["Calendar"].tap()
        sleep(1)
    }

    func testNavigateToStats() throws {
        app.tabBars.buttons["Stats"].tap()
        sleep(1)
    }
}
