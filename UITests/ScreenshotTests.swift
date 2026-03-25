import XCTest

final class ScreenshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
    }

    // MARK: - English Screenshots

    @MainActor
    func testCaptureEnglishScreenshots() throws {
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-hasCompletedOnboarding", "YES",
            "-screenshotMode", "YES"
        ]
        app.launch()

        // SS1: Home — tap no-buy to show streak
        let noBuyButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Didn't Spend")
        ).firstMatch
        if noBuyButton.waitForExistence(timeout: 5) {
            noBuyButton.tap()
            sleep(2)
        }

        let ss1 = XCTAttachment(screenshot: app.screenshot())
        ss1.name = "01_Home_EN"
        ss1.lifetime = .keepAlways
        add(ss1)

        // SS2: Calendar
        let calendarTab = app.tabBars.buttons["Calendar"]
        calendarTab.tap()
        sleep(2)

        let ss2 = XCTAttachment(screenshot: app.screenshot())
        ss2.name = "02_Calendar_EN"
        ss2.lifetime = .keepAlways
        add(ss2)

        // SS3: Stats
        let statsTab = app.tabBars.buttons["Stats"]
        statsTab.tap()
        sleep(2)

        let ss3 = XCTAttachment(screenshot: app.screenshot())
        ss3.name = "03_Stats_EN"
        ss3.lifetime = .keepAlways
        add(ss3)

        // SS4: Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        sleep(2)

        let ss4 = XCTAttachment(screenshot: app.screenshot())
        ss4.name = "04_Settings_EN"
        ss4.lifetime = .keepAlways
        add(ss4)

        // SS5: Settings scroll
        app.swipeUp()
        sleep(1)

        let ss5 = XCTAttachment(screenshot: app.screenshot())
        ss5.name = "05_Settings_About_EN"
        ss5.lifetime = .keepAlways
        add(ss5)
    }

    @MainActor
    func testCaptureOnboarding() throws {
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-hasCompletedOnboarding", "NO",
            "-screenshotMode", "YES"
        ]
        app.launch()
        sleep(2)

        let ss = XCTAttachment(screenshot: app.screenshot())
        ss.name = "06_Onboarding_EN"
        ss.lifetime = .keepAlways
        add(ss)
    }

    @MainActor
    func testCapturePaywall() throws {
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-hasCompletedOnboarding", "YES",
            "-screenshotMode", "YES"
        ]
        app.launch()

        // Navigate to Settings and tap Pro upgrade
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        sleep(1)

        let upgradeButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@", "Upgrade", "Pro")
        ).firstMatch
        if upgradeButton.waitForExistence(timeout: 5) {
            upgradeButton.tap()
            sleep(2)

            let ss = XCTAttachment(screenshot: app.screenshot())
            ss.name = "07_Paywall_EN"
            ss.lifetime = .keepAlways
            add(ss)
        }
    }
}
