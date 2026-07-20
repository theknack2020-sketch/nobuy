import XCTest

final class SimScreenshots: XCTestCase {
    @MainActor let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = true
        app.launchArguments += ["-hasCompletedOnboarding", "true"]
        app.launch()
    }

    func testCaptureAllScreens() throws {
        sleep(2)

        let screenshot1 = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "01_home_empty"
        attachment1.lifetime = .keepAlways
        add(attachment1)

        // Calendar
        app.goToSection("Calendar")
        sleep(2)
        let screenshot2 = app.screenshot()
        let attachment2 = XCTAttachment(screenshot: screenshot2)
        attachment2.name = "02_calendar"
        attachment2.lifetime = .keepAlways
        add(attachment2)

        // Stats
        app.goToSection("Stats")
        sleep(2)
        let screenshot3 = app.screenshot()
        let attachment3 = XCTAttachment(screenshot: screenshot3)
        attachment3.name = "03_stats"
        attachment3.lifetime = .keepAlways
        add(attachment3)

        // Settings
        app.goToSection("Settings")
        sleep(2)
        let screenshot4 = app.screenshot()
        let attachment4 = XCTAttachment(screenshot: screenshot4)
        attachment4.name = "04_settings"
        attachment4.lifetime = .keepAlways
        add(attachment4)
    }
}
