import XCTest

final class NoBuyUITests: XCTestCase {
    @MainActor let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["-hasCompletedOnboarding", "true"]
        app.launch()
    }

    func testTabBarExists() throws {
        XCTAssertTrue(app.sectionExists("Today"), "Today tab should exist")
    }

    func testNavigateToSettings() throws {
        XCTAssertTrue(app.sectionExists("Settings"), "Settings tab should exist")
        app.goToSection("Settings")
        sleep(1)
    }

    func testNavigateToCalendar() throws {
        app.goToSection("Calendar")
        sleep(1)
    }

    func testNavigateToStats() throws {
        app.goToSection("Stats")
        sleep(1)
    }
}
