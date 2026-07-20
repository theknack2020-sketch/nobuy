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
        XCTAssertTrue(app.sectionExists("Today"), "Today section should exist")

        // 2. Navigate to Calendar
        app.goToSection("Calendar")
        sleep(1)

        // 3. Navigate to Stats
        app.goToSection("Stats")
        sleep(1)

        // 4. Navigate to Settings
        app.goToSection("Settings")
        sleep(1)

        // 5. Back to Home
        app.goToSection("Today")
        sleep(1)
    }
}
