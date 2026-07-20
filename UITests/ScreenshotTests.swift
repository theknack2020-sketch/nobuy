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
        sleep(2)

        // Demo data (23-day streak, savings, challenge 23/30, Pro unlocked)
        // is seeded by DemoMode/DemoSeeder via -screenshotMode.

        // SS1: Home hero — streak glow + savings + challenge card
        let ss1 = XCTAttachment(screenshot: app.screenshot())
        ss1.name = "01_Home_EN"
        ss1.lifetime = .keepAlways
        add(ss1)

        // SS2: Calendar — a mostly-green month with credible accents
        app.goToSection("Calendar")
        sleep(2)

        let ss2 = XCTAttachment(screenshot: app.screenshot())
        ss2.name = "02_Calendar_EN"
        ss2.lifetime = .keepAlways
        add(ss2)

        // SS3: Stats top — savings estimate + achievements
        app.goToSection("Stats")
        sleep(2)

        let ss3 = XCTAttachment(screenshot: app.screenshot())
        ss3.name = "03_Stats_EN"
        ss3.lifetime = .keepAlways
        add(ss3)

        // SS4: Stats scrolled — the unlocked Pro charts (Pro-value frame)
        app.swipeUp()
        sleep(1)

        let ss4 = XCTAttachment(screenshot: app.screenshot())
        ss4.name = "04_Stats_Pro_Charts_EN"
        ss4.lifetime = .keepAlways
        add(ss4)

        // SS5: Settings
        app.goToSection("Settings")
        sleep(2)

        let ss5 = XCTAttachment(screenshot: app.screenshot())
        ss5.name = "05_Settings_EN"
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
        app.goToSection("Settings")
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
