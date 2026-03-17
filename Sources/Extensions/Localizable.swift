import Foundation

// MARK: - Localization Keys
// All user-facing strings centralized for easy TR/EN management

enum L10n {
    // MARK: - Tabs
    static let tabToday = String(localized: "tab_today", defaultValue: "Bugün")
    static let tabCalendar = String(localized: "tab_calendar", defaultValue: "Takvim")
    static let tabSettings = String(localized: "tab_settings", defaultValue: "Ayarlar")

    // MARK: - Home
    static let appTitle = "NoBuy"
    static let dayStreak = String(localized: "day_streak", defaultValue: "gün streak")
    static func longestStreak(_ days: Int) -> String {
        String(format: String(localized: "longest_streak_format", defaultValue: "En uzun: %d gün"), days)
    }
    static let noBuyButton = String(localized: "nobuy_button", defaultValue: "Bugün Harcama Yapmadım")
    static let noBuyDone = String(localized: "nobuy_done", defaultValue: "Harcama Yapmadım ✓")
    static let spentButton = String(localized: "spent_button", defaultValue: "Harcama yaptım")
    static let noRecordYet = String(localized: "no_record_yet", defaultValue: "Bugün henüz kayıt yok")
    static let noBuyToday = String(localized: "nobuy_today", defaultValue: "Bugün harcama yapmadın! 💪")
    static let spentToday = String(localized: "spent_today", defaultValue: "Bugün harcama yaptın")
    static let thisMonth = String(localized: "this_month", defaultValue: "Bu Ay")
    static func monthSummary(_ noBuy: Int, _ total: Int) -> String {
        String(format: String(localized: "month_summary_format", defaultValue: "/ %d gün harcamasız"), total)
    }

    // MARK: - Spend Options
    static let spendTypeQuestion = String(localized: "spend_type_question", defaultValue: "Ne tür harcama yaptın?")
    static let mandatorySpend = String(localized: "mandatory_spend", defaultValue: "Sadece Zorunlu Harcama")
    static let mandatoryDesc = String(localized: "mandatory_desc", defaultValue: "Kira, fatura, ulaşım — streak bozulmaz")
    static let discretionarySpend = String(localized: "discretionary_spend", defaultValue: "İsteğe Bağlı Harcama")
    static let discretionaryDesc = String(localized: "discretionary_desc", defaultValue: "Yeme-içme, alışveriş, eğlence")
    static let cancel = String(localized: "cancel", defaultValue: "İptal")

    // MARK: - Calendar
    static let calendarTitle = String(localized: "calendar_title", defaultValue: "Takvim")
    static let summary = String(localized: "summary", defaultValue: "Özet")
    static let noBuyDays = String(localized: "nobuy_days", defaultValue: "Harcamasız")
    static let spentDays = String(localized: "spent_days", defaultValue: "Harcamalı")
    static let unrecordedDays = String(localized: "unrecorded_days", defaultValue: "Kayıtsız")

    // MARK: - Settings
    static let settingsTitle = String(localized: "settings_title", defaultValue: "Ayarlar")
    static let mandatoryCategories = String(localized: "mandatory_categories", defaultValue: "Zorunlu Harcamalar")
    static let mandatoryCategoriesFooter = String(localized: "mandatory_categories_footer", defaultValue: "Bu kategorilerdeki harcamalar streak'ini bozmaz.")
    static let addCategory = String(localized: "add_category", defaultValue: "Kategori Ekle")
    static let newCategory = String(localized: "new_category", defaultValue: "Yeni Kategori")
    static let categoryName = String(localized: "category_name", defaultValue: "Kategori adı")
    static let add = String(localized: "add", defaultValue: "Ekle")
    static let reminders = String(localized: "reminders", defaultValue: "Hatırlatmalar")
    static let notifications = String(localized: "notifications", defaultValue: "Bildirimler")
    static let dailyReminder = String(localized: "daily_reminder", defaultValue: "Günlük Hatırlatma")
    static let dailyReminderFooter = String(localized: "daily_reminder_footer", defaultValue: "Her akşam günü kaydetmeni hatırlatır.")
    static let streakNotifications = String(localized: "streak_notifications", defaultValue: "Streak Bildirimleri")
    static let streakNotificationsFooter = String(localized: "streak_notifications_footer", defaultValue: "Yeni streak rekorlarında bildirim alırsın.")
    static let time = String(localized: "time_label", defaultValue: "Saat")
    static let data = String(localized: "data_section", defaultValue: "Veri")
    static let deleteAllData = String(localized: "delete_all_data", defaultValue: "Tüm Verileri Sil")
    static let about = String(localized: "about", defaultValue: "Hakkında")
    static let version = String(localized: "version", defaultValue: "Versiyon")
    static let rateApp = String(localized: "rate_app", defaultValue: "Uygulamayı Değerlendir")

    // MARK: - Onboarding
    static let onboardingTitle1 = String(localized: "onboarding_title1", defaultValue: "Harcamasız Günlerini Takip Et")
    static let onboardingDesc1 = String(localized: "onboarding_desc1", defaultValue: "Her gün tek bir butonla kayıt yap. Basit, hızlı, etkili.")
    static let onboardingTitle2 = String(localized: "onboarding_title2", defaultValue: "Streak'ini Büyüt")
    static let onboardingDesc2 = String(localized: "onboarding_desc2", defaultValue: "Ardışık harcamasız günler streak oluşturur. Zorunlu harcamalar streak'i bozmaz.")
    static let onboardingTitle3 = String(localized: "onboarding_title3", defaultValue: "İlerlemenizi Görün")
    static let onboardingDesc3 = String(localized: "onboarding_desc3", defaultValue: "Takvim ve aylık özet ile harcama alışkanlıklarınızı değiştirin.")
    static let getStarted = String(localized: "get_started", defaultValue: "Başla")
    static let next = String(localized: "next", defaultValue: "İleri")
}
