#if DEBUG
    import Foundation

    /// Store-shots pipeline routing: `-uiState <key>` opens the exact screen a
    /// screenshot panel needs (pair with `-demoData` for seeded content).
    /// DEBUG-only; the release binary never routes.
    ///
    /// **The keys here and the `uiState` values in `.asc/shots/panels-geometry.json` are one
    /// vocabulary.** They drifted apart in v2.0.0: the panel set was written against the new
    /// design's screens (`today-quiet-dark`, `settings-privacy-light`, …) while the router still
    /// only knew the v1 six — so every capture would have landed on the default screen and the
    /// whole set would have shown Today six times. Nothing would have failed; the panels would
    /// just have been wrong.
    ///
    /// A key that is not in this enum returns nil, which is why `assertMatchesPanelGeometry()`
    /// exists: an unroutable key must be a loud failure before the capture run, not a silent one
    /// during it.
    enum ScreenshotTour {
        enum State: String, CaseIterable {
            // v2.0.0 panel set — one case per `uiState` in panels-geometry.json.
            case todayQuietDark = "today-quiet-dark"
            case calendarLight = "calendar-light"
            case urgeRunningDark = "urge-running-dark"
            case widgetHomeLight = "widget-home-light"
            /// Today in the salmon finish. The finishes differ by a VALUE step, not a hue —
            /// "silvering is procedure, not texture" — so five swatches side by side prove
            /// nothing at panel scale, while one full dial wearing a warm finish does. It is
            /// also the only way to show paid value working with no gate language on screen.
            case todaySalmonLight = "today-salmon-light"
            case settingsPrivacyLight = "settings-privacy-light"

            // Kept so an older capture script still routes rather than silently landing on Today.
            case today, calendar, stats, statsCharts, urge, checklist
        }

        static var state: State? {
            let args = ProcessInfo.processInfo.arguments
            guard let i = args.firstIndex(of: "-uiState"), args.indices.contains(i + 1)
            else { return nil }
            return State(rawValue: args[i + 1])
        }

        /// Root tab index for the requested state.
        static var tabIndex: Int? {
            switch state {
            case .today, .todayQuietDark, .urge, .urgeRunningDark, .checklist, .widgetHomeLight: 0
            case .calendar, .calendarLight: 1
            case .stats, .statsCharts: 2
            case .settingsPrivacyLight: 3
            case .todaySalmonLight: 0
            case nil: nil
            }
        }

        /// The sheet a state opens on top of its tab, if any.
        enum Sheet { case urgeSurfing, checklist }

        static var sheet: Sheet? {
            switch state {
            case .urge, .urgeRunningDark: .urgeSurfing
            case .checklist: .checklist
            default: nil
            }
        }

        /// The dial finish a panel is photographed in, when it is not the default.
        static var finish: String? {
            state == .todaySalmonLight ? "salmon" : nil
        }

        /// The appearance the panel was designed against. The capture script sets it before
        /// launch; declared here so the two cannot disagree.
        static var prefersDark: Bool {
            switch state {
            case .todayQuietDark, .urgeRunningDark: true
            default: false
            }
        }
    }
#endif
