import XCTest

final class ScreenshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-hasCompletedOnboarding", "YES"]
        app.launch()
    }

    @MainActor
    func testCaptureAllScreenshots() throws {
        // 1. Mark no-buy to get streak
        let noBuyButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Harcama Yapmadım")
        ).firstMatch
        if noBuyButton.waitForExistence(timeout: 5) {
            noBuyButton.tap()
            sleep(2)
        }

        // SS1: Home with streak
        let ss1 = XCTAttachment(screenshot: app.screenshot())
        ss1.name = "01_Home"
        ss1.lifetime = .keepAlways
        add(ss1)

        // 2. Calendar
        app.tabBars.buttons["Takvim"].tap()
        sleep(2)
        let ss2 = XCTAttachment(screenshot: app.screenshot())
        ss2.name = "02_Calendar"
        ss2.lifetime = .keepAlways
        add(ss2)

        // 3. Settings
        app.tabBars.buttons["Ayarlar"].tap()
        sleep(2)
        let ss3 = XCTAttachment(screenshot: app.screenshot())
        ss3.name = "03_Settings"
        ss3.lifetime = .keepAlways
        add(ss3)
    }
}
