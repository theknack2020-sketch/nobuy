import Foundation

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requiredStreak: Int?
    let requiredNoBuyDays: Int?
    var isUnlocked: Bool = false
    var unlockedDate: Date?

    static let all: [Achievement] = [
        Achievement(id: "first_day", title: "First Step", description: "Log your first no-spend day", icon: "star.fill", requiredStreak: 1, requiredNoBuyDays: nil),
        Achievement(id: "streak_3", title: "3-Day Warrior", description: "3 consecutive no-spend days", icon: "flame.fill", requiredStreak: 3, requiredNoBuyDays: nil),
        Achievement(id: "streak_7", title: "Week Champion", description: "7 consecutive no-spend days", icon: "trophy.fill", requiredStreak: 7, requiredNoBuyDays: nil),
        Achievement(id: "streak_14", title: "Two-Week Master", description: "14 consecutive no-spend days", icon: "medal.fill", requiredStreak: 14, requiredNoBuyDays: nil),
        Achievement(id: "streak_30", title: "Month Legend", description: "30 consecutive no-spend days", icon: "crown.fill", requiredStreak: 30, requiredNoBuyDays: nil),
        Achievement(id: "streak_60", title: "Iron Will", description: "60 consecutive no-spend days", icon: "bolt.shield.fill", requiredStreak: 60, requiredNoBuyDays: nil),
        Achievement(id: "streak_100", title: "100-Day Club", description: "100 consecutive no-spend days", icon: "star.circle.fill", requiredStreak: 100, requiredNoBuyDays: nil),
        Achievement(id: "streak_365", title: "Year Hero", description: "365 consecutive no-spend days", icon: "sparkles", requiredStreak: 365, requiredNoBuyDays: nil),
        Achievement(id: "total_30", title: "30 Days Total", description: "30 no-spend days in total", icon: "calendar.badge.checkmark", requiredStreak: nil, requiredNoBuyDays: 30),
        Achievement(id: "total_100", title: "Hundredth Day", description: "100 no-spend days in total", icon: "gift.fill", requiredStreak: nil, requiredNoBuyDays: 100),
        Achievement(id: "perfect_week", title: "Perfect Week", description: "No spending on all 7 days of a week", icon: "checkmark.seal.fill", requiredStreak: 7, requiredNoBuyDays: nil),
        Achievement(id: "perfect_month", title: "Perfect Month", description: "No spending on every day of a month", icon: "rosette", requiredStreak: nil, requiredNoBuyDays: nil),
    ]
}
