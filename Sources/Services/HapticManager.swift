import UIKit

@MainActor
enum HapticManager {
    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private static let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    static func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        switch style {
        case .light: impactLight.impactOccurred()
        case .medium: impactMedium.impactOccurred()
        case .heavy: impactHeavy.impactOccurred()
        case .soft: impactSoft.impactOccurred()
        case .rigid: impactRigid.impactOccurred()
        @unknown default: impactMedium.impactOccurred()
        }
    }

    /// Light tap for button presses
    static func tap() {
        impactLight.impactOccurred()
    }

    /// Strong success feedback for marking a no-buy day
    static func noBuySuccess() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Success notification feedback
    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning feedback for destructive or risky actions
    static func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error feedback
    static func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    /// Feedback when a streak breaks
    static func streakBreak() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Heavy impact for streak milestones
    static func streakMilestone() {
        impactHeavy.impactOccurred()
    }

    /// Light feedback for toggling back
    static func toggle() {
        selectionGenerator.selectionChanged()
    }

    /// Tab switch / selection changed feedback
    static func selection() {
        selectionGenerator.selectionChanged()
    }

    /// Soft feedback for subtle interactions
    static func soft() {
        impactSoft.impactOccurred()
    }

    /// Rigid impact for confirmations
    static func rigid() {
        impactRigid.impactOccurred()
    }

    /// Double-tap pattern for celebration
    static func celebration() {
        impactHeavy.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Delete/destructive action feedback
    static func delete() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Save action feedback
    static func save() {
        notificationGenerator.notificationOccurred(.success)
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }
}
