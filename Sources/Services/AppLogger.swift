import Foundation
import os

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.ufukozdemir.nobuy"

    static let store = Logger(subsystem: subsystem, category: "store")
    static let data = Logger(subsystem: subsystem, category: "data")
    static let notification = Logger(subsystem: subsystem, category: "notification")
    static let general = Logger(subsystem: subsystem, category: "general")
}
