#if DEBUG
    import Foundation

    /// Store-shots pipeline routing: `-uiState <key>` opens the exact screen a
    /// screenshot panel needs (pair with `-demoData` for seeded content).
    /// DEBUG-only; the release binary never routes.
    enum ScreenshotTour {
        enum State: String {
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
            case .today, .urge, .checklist: 0
            case .calendar: 1
            case .stats, .statsCharts: 2
            case nil: nil
            }
        }
    }
#endif
