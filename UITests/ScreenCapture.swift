import XCTest

final class ScreenCapture: XCTestCase {
    @MainActor let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = true
        app.launchArguments += ["-hasCompletedOnboarding", "true"]
        app.launch()
    }

    func testCaptureHomeScreen() throws {
        sleep(2)
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "HomeScreen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCaptureCalendar() throws {
        app.goToSection("Calendar")
        sleep(2)
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CalendarScreen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCaptureStats() throws {
        app.goToSection("Stats")
        sleep(2)
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "StatsScreen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCaptureSettings() throws {
        app.goToSection("Settings")
        sleep(2)
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "SettingsScreen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
