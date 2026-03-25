import CoreSpotlight
import UniformTypeIdentifiers
import os

enum SpotlightService {
    static func indexStreak(_ streak: Int) {
        let attributes = CSSearchableItemAttributeSet(contentType: .item)
        attributes.title = "NoBuy Streak: \(streak) days"
        attributes.contentDescription = "Your current no-spend streak is \(streak) days"
        attributes.keywords = ["nobuy", "streak", "no spend", "savings"]

        let item = CSSearchableItem(
            uniqueIdentifier: "com.ufukozdemir.nobuy.streak",
            domainIdentifier: "com.ufukozdemir.nobuy",
            attributeSet: attributes
        )
        item.expirationDate = Calendar.current.date(byAdding: .day, value: 1, to: .now)

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error {
                AppLogger.general.error("Spotlight streak indexing failed: \(error.localizedDescription)")
            }
        }
    }

    static func indexAchievement(_ achievement: Achievement) {
        let attributes = CSSearchableItemAttributeSet(contentType: .item)
        attributes.title = "NoBuy: \(achievement.title)"
        attributes.contentDescription = achievement.description
        attributes.keywords = ["nobuy", "achievement", "badge"]

        let item = CSSearchableItem(
            uniqueIdentifier: "com.ufukozdemir.nobuy.achievement.\(achievement.id)",
            domainIdentifier: "com.ufukozdemir.nobuy.achievements",
            attributeSet: attributes
        )

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error {
                AppLogger.general.error("Spotlight achievement indexing failed: \(error.localizedDescription)")
            }
        }
    }

    static func removeAll() {
        CSSearchableIndex.default().deleteAllSearchableItems { error in
            if let error {
                AppLogger.general.error("Spotlight removal failed: \(error.localizedDescription)")
            }
        }
    }
}
