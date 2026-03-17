import XCTest

final class NoBuyUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-hasCompletedOnboarding", "YES"]
        app.launch()
    }

    // MARK: - Tab Navigation

    @MainActor
    func testTabNavigation() throws {
        let todayTab = app.tabBars.buttons["Bugün"]
        XCTAssertTrue(todayTab.exists, "Bugün tab should exist")

        let calendarTab = app.tabBars.buttons["Takvim"]
        XCTAssertTrue(calendarTab.exists, "Takvim tab should exist")
        calendarTab.tap()

        let settingsTab = app.tabBars.buttons["Ayarlar"]
        XCTAssertTrue(settingsTab.exists, "Ayarlar tab should exist")
        settingsTab.tap()

        todayTab.tap()
    }

    // MARK: - Home Screen Elements

    @MainActor
    func testHomeScreenElements() throws {
        // Streak badge — textCase(.uppercase) renders visually but accessibility uses original
        let streakLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "streak")
        ).firstMatch
        XCTAssertTrue(streakLabel.waitForExistence(timeout: 3),
                      "Streak badge label should be visible")

        // Main action button area
        let noBuyText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Harcama Yapmadım")
        ).firstMatch
        XCTAssertTrue(noBuyText.waitForExistence(timeout: 3),
                      "No-buy button text should exist")

        // Monthly summary
        XCTAssertTrue(app.staticTexts["Bu Ay"].exists, "Monthly summary should exist")
    }

    // MARK: - Mark No Buy Day

    @MainActor
    func testMarkNoBuyDay() throws {
        // Find and tap the main button
        let noBuyButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Harcama Yapmadım")
        ).firstMatch

        guard noBuyButton.waitForExistence(timeout: 3) else {
            XCTFail("No-buy button not found")
            return
        }
        noBuyButton.tap()
        sleep(1)

        // Check status text changed
        let doneText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "harcama yapmadın")
        ).firstMatch
        XCTAssertTrue(doneText.waitForExistence(timeout: 3),
                      "Status should update after marking no-buy")
    }

    // MARK: - Spend Options Flow

    @MainActor
    func testSpendOptionsFlow() throws {
        // First check if "Harcama yaptım" link exists
        let spentLink = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Harcama yaptım")
        ).firstMatch

        guard spentLink.waitForExistence(timeout: 3) else {
            XCTFail("'Harcama yaptım' link not found")
            return
        }
        spentLink.tap()

        // Wait for sheet
        let sheetTitle = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Ne tür harcama")
        ).firstMatch
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5),
                      "Spend options sheet should appear")
    }

    // MARK: - Calendar Screen

    @MainActor
    func testCalendarScreen() throws {
        app.tabBars.buttons["Takvim"].tap()
        sleep(1)

        let summaryLabel = app.staticTexts["Özet"]
        XCTAssertTrue(summaryLabel.waitForExistence(timeout: 3),
                      "Calendar summary section should exist")

        // Check summary pills exist
        let noBuyPill = app.staticTexts["Harcamasız"]
        XCTAssertTrue(noBuyPill.exists, "No-buy pill should exist")
    }

    // MARK: - Settings Screen

    @MainActor
    func testSettingsScreen() throws {
        app.tabBars.buttons["Ayarlar"].tap()
        sleep(2)

        // Section headers
        let mandatoryHeader = app.staticTexts["Zorunlu Harcamalar"]
        XCTAssertTrue(mandatoryHeader.waitForExistence(timeout: 5),
                      "Mandatory categories section should exist")

        // Version info
        let versionLabel = app.staticTexts["Versiyon"]
        XCTAssertTrue(versionLabel.exists, "Version label should exist in About section")
    }

    // MARK: - Add Category

    @MainActor
    func testAddCategory() throws {
        app.tabBars.buttons["Ayarlar"].tap()
        sleep(2)

        let addButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Kategori Ekle")
        ).firstMatch
        guard addButton.waitForExistence(timeout: 5) else {
            XCTFail("Add category button not found")
            return
        }
        addButton.tap()
        sleep(1)

        // Alert should appear
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "Add category alert should appear")

        // Type name and add
        let textField = alert.textFields.firstMatch
        if textField.exists {
            textField.tap()
            textField.typeText("Eğlence")
            alert.buttons["Ekle"].tap()
            sleep(1)

            // Should appear in list
            XCTAssertTrue(app.staticTexts["Eğlence"].waitForExistence(timeout: 3),
                          "New category should appear in list")
        }
    }
}
