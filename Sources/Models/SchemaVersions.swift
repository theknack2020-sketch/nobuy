import SwiftData

// MARK: - Current Schema Version

/// Current versioned schema for NoBuy data models.
/// When modifying DayRecord or MandatoryCategory, increment the version
/// and add a migration stage.
enum NoBuySchema: VersionedSchema {
    nonisolated(unsafe) static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [DayRecord.self, MandatoryCategory.self]
    }
}

// MARK: - Migration Plan

/// Migration plan for NoBuy data models.
/// Add new VersionedSchema enums and MigrationStages when the schema evolves.
///
/// Example for future V2 migration:
/// ```swift
/// enum NoBuySchemaV2: VersionedSchema {
///     static var versionIdentifier = Schema.Version(2, 0, 0)
///     static var models: [any PersistentModel.Type] {
///         [DayRecord.self, MandatoryCategory.self]
///     }
/// }
/// ```
/// Then add to schemas array and create a lightweight/custom stage.
enum NoBuyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [NoBuySchema.self]
    }

    static var stages: [MigrationStage] {
        [] // No migrations yet — single version
    }
}
