import SwiftData
import SwiftUI
import UserNotifications

// MARK: - Onboarding — four screens that end INSIDE the product (Escapement, v2.0.0)
//
// Held to the same higher bar as the paywall (owner law 2026-08-07), and shaped by the round:
//
//   1. What this is — the day dial carrying a real run, not an abstract splash.
//   2. The record — the five truths taught on a real week row, in the exact marks the app uses.
//   3. The promise — no account, no bank, no analytics; the deal, permanently.
//   4. Tonight — the REAL question, answerable on the spot. There is no "Get started"
//      dead-end: the first session ends with day one already in the record.
//   4b. The permission moment — asked only AFTER day one is kept, in one plain sentence, with
//      the refused path drawn: declining changes nothing but the reminder, and the single
//      re-offer lives in Settings.
//
// Skip is present from screen one and lands on Today, where the shape of the answer is already
// visible. Progress is four index ticks — the product's own mark — not dots.
//
// What this version deliberately DROPPED: the v1 goal picker and daily-spend estimate. Setup is
// four screens and one question; the goal now lives in Settings, where it can be set, changed
// or ignored without standing between a new user and their first answer.

struct OnboardingScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("notificationHour") private var notificationHour = 21
    @AppStorage("notificationMinute") private var notificationMinute = 30

    @State private var page = 0
    @State private var answered: DayTruth?
    @State private var drawn = false

    /// The three type roles this screen sizes in points, each scaling with the user's setting
    /// and floored where it stops doing its job: the teaching title, the day-one count, and the
    /// question — which is the same 20pt question Today asks, because it IS Today's question.
    @ScaledMetric(relativeTo: .largeTitle) private var scaledTitle: CGFloat = 28
    @ScaledMetric(relativeTo: .largeTitle) private var scaledCount: CGFloat = 56
    @ScaledMetric(relativeTo: .body) private var scaledQuestion: CGFloat = 20

    private var isRegular: Bool { sizeClass == .regular }

    /// Four teaching screens; the permission moment is a fifth state of the last one, reached
    /// only by answering.
    private let pageCount = 4

    var body: some View {
        ZStack {
            Color.surfaceField.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                // Every page scrolls. Onboarding is held to the higher bar by owner law, and it
                // was the one surface with no ScrollView anywhere: at large Dynamic Type the copy
                // simply ran off the bottom, taking the Continue button with it on the page that
                // asks for a permission. `scrollBounceBehavior(.basedOnSize)` keeps the short
                // pages feeling fixed, so nothing moves at the default text size.
                TabView(selection: $page) {
                    scrollable(whatThisIs).tag(0)
                    scrollable(theRecord).tag(1)
                    scrollable(thePromise).tag(2)
                    scrollable(tonight).tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : DS.Anim.functional, value: page)
            }
        }
        .task {
            if reduceMotion {
                drawn = true
            } else {
                withAnimation(DS.Anim.gauge) { drawn = true }
            }
        }
    }

    // MARK: - Chrome

    private func scrollable(_ page: some View) -> some View {
        ScrollView {
            page.frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var topBar: some View {
        HStack {
            // Four index ticks: the same triangle that marks "now" on a dial. Dots would be a
            // borrowed convention; this is the product's own mark doing the same job.
            HStack(spacing: DS.Spacing.sm) {
                ForEach(0 ..< pageCount, id: \.self) { index in
                    IndexTriangle()
                        .fill(index <= page ? Color.accentKept : Color.stateNotYet)
                        .frame(width: 10, height: 8)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(page + 1) of \(pageCount)")

            Spacer()

            if answered == nil {
                Button("Skip") { finish() }
                    .font(.subheadline)
                    .foregroundStyle(.inkSecondary)
                    .accessibilityIdentifier("onboarding_skip")
            }
        }
        .padding(.horizontal, DS.Spacing.screenGutter)
        .padding(.vertical, DS.Spacing.md)
    }

    private func continueButton(_ title: String = "Continue", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.inkOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(Color.accentKept))
        }
        .buttonStyle(.scale)
        .padding(.horizontal, DS.Spacing.screenGutter)
        .padding(.bottom, DS.Spacing.xxl)
    }

    private func teachingPage(
        title: String,
        copy: String,
        @ViewBuilder illustration: () -> some View,
        @ViewBuilder footer: () -> some View
    ) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: DS.Spacing.lg)

            illustration()
                .frame(maxWidth: .infinity)

            Spacer(minLength: DS.Spacing.xl)

            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text(title)
                    .font(.system(size: max(scaledTitle, 24), weight: .bold))
                    .foregroundStyle(.inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(copy)
                    .font(.body)
                    .foregroundStyle(.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.screenGutter)

            Spacer(minLength: DS.Spacing.xl)

            footer()
        }
    }

    // MARK: - 1 · What this is

    private var whatThisIs: some View {
        teachingPage(
            title: "One question,\nevery evening.",
            copy: "Did you buy anything unnecessary today? One tap answers it, and the days you keep accumulate into a run."
        ) {
            // A real run on a real dial. An abstract splash would teach nothing about the one
            // object the whole product is built from.
            DialFace(size: 220, scale: .day, progress: drawn ? 0.86 : 0, handPosition: 0.86) {
                VStack(spacing: 0) {
                    Text("23")
                        .font(.system(size: max(scaledCount, 44), weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.inkPrimary)
                    Text("days kept")
                        .font(.caption)
                        .foregroundStyle(.inkSecondary)
                }
            }
        } footer: {
            continueButton { withAnimation(reduceMotion ? nil : DS.Anim.functional) { page = 1 } }
        }
    }

    // MARK: - 2 · The record

    private var theRecord: some View {
        teachingPage(
            title: "Every day gets\nits truth.",
            copy: "Rent, utilities, transport and groceries never break the run. A spent day is recorded, never punished — and one freeze a month covers a slip."
        ) {
            VStack(spacing: DS.Spacing.lg) {
                // The five truths on a real week row, in the exact marks the calendar uses.
                HStack(spacing: DS.Spacing.cellGap) {
                    ForEach(Array(weekTeaching.enumerated()), id: \.offset) { index, item in
                        DayCell(day: 10 + index, truth: item.truth)
                    }
                }
                .padding(.horizontal, DS.Spacing.screenGutter)

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    ForEach(Array(weekTeaching.enumerated()), id: \.offset) { _, item in
                        if let caption = item.caption {
                            HStack(spacing: DS.Spacing.sm) {
                                DayMark(truth: item.truth)
                                Text(caption)
                                    .font(.footnote)
                                    .foregroundStyle(.inkSecondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.Spacing.screenGutter)
            }
        } footer: {
            continueButton { withAnimation(reduceMotion ? nil : DS.Anim.functional) { page = 2 } }
        }
    }

    private var weekTeaching: [(truth: DayTruth, caption: String?)] {
        [
            (.kept, "kept"),
            (.mandatoryOnly, "essentials only — still kept"),
            (.spent, "spent — a fact, not a fault"),
            (.frozen, "frozen — one mercy a month"),
            (.notYet, nil),
        ]
    }

    // MARK: - 3 · The promise

    private var thePromise: some View {
        teachingPage(
            title: "Yours alone,\non this phone.",
            copy: "No account. No bank connection. No analytics. The record lives on this device and nowhere else — that is the deal, permanently."
        ) {
            DialFace(size: 160, scale: .interval, progress: drawn ? 1 : 0, handPosition: nil) {
                Image(systemName: "iphone")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.inkSecondary)
                    .accessibilityHidden(true)
            }
        } footer: {
            continueButton { withAnimation(reduceMotion ? nil : DS.Anim.functional) { page = 3 } }
        }
    }

    // MARK: - 4 · Tonight (and 4b, the permission moment)

    @ViewBuilder
    private var tonight: some View {
        if answered == nil {
            askTonight
        } else {
            permissionMoment
        }
    }

    private var askTonight: some View {
        VStack(spacing: 0) {
            Spacer(minLength: DS.Spacing.lg)

            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Start with today.")
                    .font(.system(size: max(scaledTitle, 24), weight: .bold))
                    .foregroundStyle(.inkPrimary)

                Text("It is \(Self.clock.string(from: .now)) on \(Self.weekday.string(from: .now)). The day closes at midnight.")
                    .font(.body)
                    .foregroundStyle(.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.screenGutter)

            Spacer(minLength: DS.Spacing.xl)

            // The real question, not a rehearsal of it.
            VStack(spacing: DS.Spacing.lg) {
                Text("Buy anything unnecessary today?")
                    .font(.system(size: max(scaledQuestion, 20), weight: .semibold))
                    .foregroundStyle(.inkPrimary)
                    .multilineTextAlignment(.center)

                HStack(spacing: DS.Spacing.md) {
                    answerButton("No", isPrimary: true, identifier: "onboarding_answer_no") {
                        record(.kept)
                    }
                    answerButton("Yes", isPrimary: false, identifier: "onboarding_answer_yes") {
                        record(.spent)
                    }
                }

                Text("Rent, utilities, transport and groceries never count.")
                    .font(.caption)
                    .foregroundStyle(.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(DS.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.sheet)
                    .fill(Color.surfaceDial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.sheet)
                            .strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.hairline)
                    )
            )
            .padding(.horizontal, DS.Spacing.screenGutter)

            Text("Answering starts the record — day one.")
                .font(.caption)
                .foregroundStyle(.inkSecondary)
                .padding(.top, DS.Spacing.md)

            Spacer(minLength: DS.Spacing.xxl)
        }
    }

    private func answerButton(
        _ title: String,
        isPrimary: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(isPrimary ? Color.inkOnAccent : Color.inkPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(isPrimary ? Color.accentKept : Color.surfaceDial)
                        .overlay(
                            Capsule().strokeBorder(
                                isPrimary ? Color.clear : Color.accentSpentText,
                                lineWidth: DS.Stroke.hairline
                            )
                        )
                )
        }
        .buttonStyle(.scale)
        .accessibilityIdentifier(identifier)
    }

    /// 4b — asked only after day one is already in the record. The sentence earns the
    /// permission; the refused path changes nothing else and is stated plainly.
    private var permissionMoment: some View {
        VStack(spacing: 0) {
            Spacer(minLength: DS.Spacing.lg)

            VStack(spacing: DS.Spacing.sm) {
                Text("1")
                    .font(.system(size: max(scaledCount, 44), weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.inkPrimary)

                Text(answered == .kept ? "Day one, kept." : "Day one, recorded.")
                    .font(.system(size: max(scaledTitle * 0.86, 22), weight: .bold))
                    .foregroundStyle(.inkPrimary)

                Text("\(Self.longDate.string(from: .now)) — answered, in the record.")
                    .font(.footnote)
                    .foregroundStyle(.inkSecondary)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: DS.Spacing.xl)

            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("One reminder at 21:30.")
                    .font(.headline)
                    .foregroundStyle(.inkPrimary)

                // Every clause here is now literally true, and was made true rather than softened:
                // the re-engagement class was deleted (it was the "marketing" this sentence
                // disclaims, and nothing could switch it off), streak alerts default OFF so this
                // really is the only one, and the Settings toggle covers it.
                Text("So the day gets its answer before it closes. Nothing else — no streak alerts, no marketing — and it can be turned off in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    Task { await enableReminder() }
                } label: {
                    Text("Allow the reminder")
                        .font(.headline)
                        .foregroundStyle(Color.inkOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(Color.accentKept))
                }
                .buttonStyle(.scale)
                .accessibilityIdentifier("onboarding_allow_reminder")

                Button("Without it") { finish() }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("onboarding_decline_reminder")

                Text("Declining changes nothing else. The app never asks again on its own — the one re-offer lives in Settings ▸ Reminders.")
                    .font(.caption)
                    .foregroundStyle(.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DS.Spacing.lg)
            .background(RoundedRectangle(cornerRadius: DS.Radius.sheet).fill(Color.surfaceWell))
            .padding(.horizontal, DS.Spacing.screenGutter)

            Spacer(minLength: DS.Spacing.xxl)
        }
    }

    // MARK: - Actions

    /// Writes day one. The onboarding's last screen IS the product, so this is a real record —
    /// the same one Today would have written.
    private func record(_ truth: DayTruth) {
        let record = DayRecord(date: .now, didSpend: truth == .spent)
        modelContext.insert(record)
        try? modelContext.save()

        HapticManager.noBuySuccess()
        withAnimation(reduceMotion ? nil : DS.Anim.beat) { answered = truth }
    }

    private func enableReminder() async {
        let manager = NotificationManager()
        await manager.requestAuthorization()
        // The app's own switch follows the SYSTEM answer: if the user declines at the system
        // prompt, nothing here pretends a reminder was set.
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        dailyReminderEnabled = settings.authorizationStatus == .authorized
        if dailyReminderEnabled {
            notificationHour = 21
            notificationMinute = 30
            await manager.scheduleDailyReminder(hour: 21, minute: 30)
        }
        finish()
    }

    private func finish() {
        hasCompletedOnboarding = true
    }

    // MARK: - Formatters

    private static let clock: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let weekday: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    private static let longDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "d MMMM"
        return f
    }()
}
