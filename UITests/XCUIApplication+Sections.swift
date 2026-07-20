import XCTest

extension XCUIApplication {
    /// The tappable entry for a top-level section: the tab-bar item on iPhone,
    /// or the NavigationSplitView sidebar row on iPad regular width.
    private func sectionEntry(_ name: String) -> XCUIElement? {
        let candidates = [
            tabBars.buttons[name],
            buttons[name].firstMatch,
            cells.containing(.staticText, identifier: name).firstMatch,
            staticTexts[name].firstMatch,
        ]
        for candidate in candidates where candidate.waitForExistence(timeout: 2) {
            return candidate
        }
        return nil
    }

    /// True when the section entry exists on either form factor.
    func sectionExists(_ name: String) -> Bool {
        sectionEntry(name) != nil
    }

    /// Navigates to a top-level section on both iPhone and iPad.
    func goToSection(_ name: String) {
        sectionEntry(name)?.tap()
    }
}
