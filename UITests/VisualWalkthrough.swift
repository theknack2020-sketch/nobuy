import XCTest

final class VisualWalkthrough: XCTestCase {
    @MainActor let app = XCUIApplication()
    let dir = "/tmp/nobuy_screens"

    override func setUpWithError() throws {
        continueAfterFailure = true
        app.launchArguments += ["-hasCompletedOnboarding", "true"]
        app.launch()
    }

    func testWalkthroughAllTabs() throws {
        sleep(2)

        // Home
        let homeScreenshot = app.screenshot()
        let homeAttachment = XCTAttachment(screenshot: homeScreenshot)
        homeAttachment.name = "walkthrough_01_home"
        homeAttachment.lifetime = .keepAlways
        add(homeAttachment)

        // Calendar
        app.tabBars.buttons["Calendar"].tap()
        sleep(2)
        let calScreenshot = app.screenshot()
        let calAttachment = XCTAttachment(screenshot: calScreenshot)
        calAttachment.name = "walkthrough_02_calendar"
        calAttachment.lifetime = .keepAlways
        add(calAttachment)

        // Stats
        app.tabBars.buttons["Stats"].tap()
        sleep(2)
        let statsScreenshot = app.screenshot()
        let statsAttachment = XCTAttachment(screenshot: statsScreenshot)
        statsAttachment.name = "walkthrough_03_stats"
        statsAttachment.lifetime = .keepAlways
        add(statsAttachment)

        // Settings
        app.tabBars.buttons["Settings"].tap()
        sleep(2)
        let settingsScreenshot = app.screenshot()
        let settingsAttachment = XCTAttachment(screenshot: settingsScreenshot)
        settingsAttachment.name = "walkthrough_04_settings"
        settingsAttachment.lifetime = .keepAlways
        add(settingsAttachment)
    }
}
