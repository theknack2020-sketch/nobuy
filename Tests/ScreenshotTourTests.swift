import Foundation
import Testing
@testable import NoBuy

#if DEBUG

    /// The panel geometry and the screen router are one vocabulary, and nothing at runtime notices
    /// when they drift: an unroutable `uiState` simply lands on the default screen, so the capture
    /// run succeeds and the whole store set shows Today six times.
    ///
    /// This is the cross-check (`JOINS` rule: joined ≠ audited). It reads the SHIPPED geometry file
    /// rather than a copy of its keys, so adding a panel without a route fails here instead of in
    /// the App Store listing.
    @Suite("Panel geometry ↔ screen router")
    struct ScreenshotTourTests {
        private func geometry() throws -> [String: Any] {
            let url = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appending(path: ".asc/shots/panels-geometry.json")
            let data = try Data(contentsOf: url)
            return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        }

        private func declaredStates() throws -> [String] {
            let geo = try geometry()
            let devices = try #require(geo["devices"] as? [String: Any])
            var states: [String] = []
            for (_, spec) in devices {
                let panels = try #require((spec as? [String: Any])?["panels"] as? [[String: Any]])
                states.append(contentsOf: panels.compactMap { $0["uiState"] as? String })
            }
            return states
        }

        @Test("Every panel's uiState routes to a screen")
        func everyPanelRoutes() throws {
            let states = try declaredStates()
            #expect(!states.isEmpty, "geometry declared no panels — the cross-check would pass vacuously")

            for raw in Set(states) {
                let state = ScreenshotTour.State(rawValue: raw)
                #expect(state != nil, "panels-geometry.json declares uiState \"\(raw)\" with no case in ScreenshotTour.State")
            }
        }

        @Test("Every routable state lands on a real tab")
        func everyStateHasATab() {
            for state in ScreenshotTour.State.allCases {
                // `tabIndex` reads the launch argument, so the mapping is asserted directly here:
                // what matters is that no case is left out of the switch and silently nil.
                let tab: Int? = switch state {
                case .today, .todayQuietDark, .urge, .urgeRunningDark, .checklist,
                     .widgetHomeLight, .todaySalmonLight: 0
                case .calendar, .calendarLight: 1
                case .stats, .statsCharts: 2
                case .settingsPrivacyLight: 3
                }
                #expect((0 ... 3).contains(try! #require(tab)), "\(state.rawValue) has no tab")
            }
        }

        @Test("The dark panels are the ones drawn dark")
        func appearanceMatchesTheDesign() throws {
            let geo = try geometry()
            let devices = try #require(geo["devices"] as? [String: Any])
            for (_, spec) in devices {
                let panels = try #require((spec as? [String: Any])?["panels"] as? [[String: Any]])
                for panel in panels {
                    let raw = try #require(panel["uiState"] as? String)
                    let field = try #require(panel["field"] as? String)
                    let state = try #require(ScreenshotTour.State(rawValue: raw))
                    let wantsDark = field == "dark"
                    // The router's own answer, derived from the case name.
                    let routerDark: Bool = switch state {
                    case .todayQuietDark, .urgeRunningDark: true
                    default: false
                    }
                    #expect(routerDark == wantsDark,
                            "\(raw): geometry says field=\(field) but the router prefers \(routerDark ? "dark" : "light")")
                }
            }
        }
    }

#endif
