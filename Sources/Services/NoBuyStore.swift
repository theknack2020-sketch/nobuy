import Foundation
import SwiftData

// MARK: - Where the records live
//
// v2.0.0 adds a widget, and a widget cannot read the app's private container. So the store moves
// into the App Group — the one piece of this release that touches data people have been keeping
// for a year and a half.
//
// The move is **copy → verify → switch**, never move-and-hope:
//
//   1. The old file is COPIED to a staging name inside the group. The original is not touched.
//   2. Both stores are opened and their day counts compared. A copy that lost rows is not a
//      migration, it is data loss with a success message.
//   3. Only a verified copy is renamed into place. Anything else deletes the staging file and
//      the app keeps running on the old store, which is still exactly where it was.
//
// **Only the app may bring a store into existence, and it says so in the shared suite when the
// question is settled.** The first draft used "the shared file exists" as the flag, reasoning
// that the filesystem cannot disagree with itself. It can, once a second process is allowed to
// write to it: a widget refresh before the app's first post-update launch sees no shared store
// and — from inside the extension's own sandbox — no legacy one either, so SwiftData creates an
// EMPTY shared store. The app then reads that as "already migrated" and opens it. Nothing is
// deleted, but the person's whole record vanishes from the app, which is the same thing to them.
//
// So the flag is written by the APP, AFTER the file is in place (`markStoreSettled`), and every
// widget/intent call passes `creating: false` — before the flag exists they read what is there
// and create nothing.
//
// The old file is never deleted here. It stays one full version as a cold backup.

enum NoBuyStore {
    static let appGroupID = "group.com.ufukozdemir.nobuy"

    /// The group container, or nil when the entitlement is absent (a unit-test host, or a build
    /// signed before the capability existed). Nil is a supported state: the app then keeps using
    /// its own container and the widget simply has nothing to read.
    static var groupContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static var sharedStoreURL: URL? {
        groupContainerURL?.appending(path: "NoBuy.store")
    }

    private static var stagingStoreURL: URL? {
        groupContainerURL?.appending(path: "Migrating.store")
    }

    /// SwiftData's own default location, which is where every record written before v2.0.0 is.
    ///
    /// **APP PROCESS ONLY.** `.applicationSupportDirectory` resolves inside the CALLING process's
    /// container, so from the widget or the App Intent this points at the extension's own empty
    /// sandbox — not at the app's records. That is the whole reason for `storeIsSettled` below.
    static var legacyStoreURL: URL? {
        try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appending(path: "default.store")
    }

    /// Written by the APP, once, after the store question is answered for good.
    ///
    /// The first draft used "the shared file exists" as the flag, and that had a hole big enough
    /// to lose a user's entire record: a widget refresh before the app's first post-update launch
    /// finds no shared store AND no legacy store (it cannot see the app's), so SwiftData creates
    /// an EMPTY shared store — and the app then reads that as "already migrated" and opens it.
    /// Nothing is deleted, but every day the person logged disappears from the app, which is the
    /// same thing as far as they are concerned.
    ///
    /// So the rule is now: **only the app may bring a store into existence.** Until it says the
    /// question is settled, the widget and the intent read what is there and create nothing.
    private static let settledKey = "storeSettledAt"

    static var storeIsSettled: Bool {
        SharedDefaults.suite.object(forKey: settledKey) != nil
    }

    private static func markStoreSettled() {
        SharedDefaults.suite.set(Date.now.timeIntervalSince1970, forKey: settledKey)
    }

    /// SQLite keeps three files; a copy that takes only the first one silently loses every
    /// unflushed transaction in the write-ahead log.
    private static let sidecarSuffixes = ["", "-shm", "-wal"]

    // MARK: - Resolution

    /// Whichever store is the live one right now.
    ///
    /// `creating` is the app's privilege. With it false — every widget and App Intent call — an
    /// absent store resolves to nil rather than to a path SwiftData would helpfully create.
    static func resolvedStoreURL(creating: Bool) -> URL? {
        if let shared = sharedStoreURL, FileManager.default.fileExists(atPath: shared.path) {
            return shared
        }
        // Only ever non-nil in the app process (see `legacyStoreURL`).
        if let legacy = legacyStoreURL, FileManager.default.fileExists(atPath: legacy.path) {
            return legacy
        }
        guard creating else { return nil }
        // Nothing written yet: a fresh install starts life already shared.
        return sharedStoreURL
    }

    // MARK: - Container

    /// Thrown rather than papered over: a widget that cannot reach the record must say nothing,
    /// not invent an empty one.
    enum StoreError: Error { case notReadyOutsideApp }

    static func makeContainer(inMemory: Bool = false, creating: Bool = true) throws -> ModelContainer {
        let schema = Schema(versionedSchema: NoBuySchema.self)

        if inMemory {
            return try ModelContainer(
                for: schema,
                migrationPlan: NoBuyMigrationPlan.self,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        }

        // Outside the app, wait until the app has settled the question. Before that the only
        // honest answer is "I cannot see the record yet".
        if !creating, !storeIsSettled { throw StoreError.notReadyOutsideApp }

        guard let url = resolvedStoreURL(creating: creating) else {
            throw StoreError.notReadyOutsideApp
        }
        return try ModelContainer(
            for: schema,
            migrationPlan: NoBuyMigrationPlan.self,
            configurations: [ModelConfiguration(schema: schema, url: url)]
        )
    }

    // MARK: - The move

    enum MigrationOutcome: Equatable {
        /// Already shared, or nothing to move.
        case notNeeded
        case migrated(records: Int)
        /// The old store stays live and nothing was lost.
        case keptLegacy(reason: String)
    }

    @discardableResult
    static func migrateToAppGroupIfNeeded() -> MigrationOutcome {
        let fm = FileManager.default

        guard let shared = sharedStoreURL, let staging = stagingStoreURL else {
            return .keptLegacy(reason: "no app group container")
        }
        guard !fm.fileExists(atPath: shared.path) else { markStoreSettled(); return .notNeeded }
        guard let legacy = legacyStoreURL, fm.fileExists(atPath: legacy.path) else {
            // Fresh install: the app creates the shared store on first open, and saying so here
            // is what lets the widget stop holding its breath.
            markStoreSettled()
            return .notNeeded
        }

        // A staging file left by an interrupted attempt is worthless — it may be a partial copy.
        removeStore(at: staging)

        do {
            for suffix in sidecarSuffixes {
                let source = URL(fileURLWithPath: legacy.path + suffix)
                guard fm.fileExists(atPath: source.path) else { continue }
                try fm.copyItem(at: source, to: URL(fileURLWithPath: staging.path + suffix))
            }

            let legacyCount = try dayRecordCount(at: legacy)
            let copiedCount = try dayRecordCount(at: staging)
            guard copiedCount == legacyCount else {
                removeStore(at: staging)
                markStoreSettled()
                return .keptLegacy(reason: "copy held \(copiedCount) of \(legacyCount) days")
            }

            // The write-ahead log and shared-memory files move FIRST and the main `.store` LAST.
            // The other order looked harmless and was not: an interruption between the moves
            // leaves the `.store` in place with its WAL still in staging — and the next launch,
            // seeing the shared file exist, calls the migration done and wipes the staging
            // directory, taking every unflushed transaction with it.
            for suffix in sidecarSuffixes.reversed() {
                let from = URL(fileURLWithPath: staging.path + suffix)
                guard fm.fileExists(atPath: from.path) else { continue }
                try fm.moveItem(at: from, to: URL(fileURLWithPath: shared.path + suffix))
            }
            markStoreSettled()
            return .migrated(records: legacyCount)
        } catch {
            // Any failure at all leaves the original untouched and live.
            removeStore(at: staging)
            AppLogger.data.error("App Group migration kept the old store: \(error.localizedDescription)")
            markStoreSettled()
            return .keptLegacy(reason: error.localizedDescription)
        }
    }

    /// Opens an explicit URL, bypassing `resolvedStoreURL` — this runs INSIDE the migration,
    /// before anything is settled, and it is app-process-only by construction.
    private static func dayRecordCount(at url: URL) throws -> Int {
        let schema = Schema(versionedSchema: NoBuySchema.self)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: NoBuyMigrationPlan.self,
            configurations: [ModelConfiguration(schema: schema, url: url)]
        )
        let context = ModelContext(container)
        return try context.fetchCount(FetchDescriptor<DayRecord>())
    }

    private static func removeStore(at url: URL) {
        for suffix in sidecarSuffixes {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }
}

// MARK: - The defaults the widget can also read
//
// The waiting list is a Codable blob in `UserDefaults`, and the medium widget shows the nearest
// wait — so the blob has to live in the group suite too. This is the same copy-then-switch
// shape as the store, at a much smaller scale: the value is copied across on first read and the
// standard copy is left alone, so a downgrade to v1.2 still finds its data.

enum SharedDefaults {
    // `UserDefaults` is not Sendable, but a suite handle is a process-wide singleton that the
    // framework itself makes safe to touch from anywhere — the same reason `.standard` exists.
    nonisolated(unsafe) static let suite: UserDefaults =
        UserDefaults(suiteName: NoBuyStore.appGroupID) ?? .standard

    /// Reads `key` from the shared suite, seeding it once from the app's own defaults. Returns
    /// nil when neither has it — an absent value is absent, not empty (`ios-empty-fetch-is-not-no-data`).
    static func data(forKey key: String) -> Data? {
        if let shared = suite.data(forKey: key) { return shared }
        guard let legacy = UserDefaults.standard.data(forKey: key) else { return nil }
        suite.set(legacy, forKey: key)
        return legacy
    }

    /// Writes to both, for as long as one shipped version still reads the old place.
    static func set(_ value: Data, forKey key: String) {
        suite.set(value, forKey: key)
        UserDefaults.standard.set(value, forKey: key)
    }

    static func removeObject(forKey key: String) {
        suite.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
    }
}
