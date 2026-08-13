import SwiftUI
import UserNotifications

// MARK: - Urge surfing — ten minutes on the dial (Escapement, v2.0.0)
//
// The purest expression of the signature: one wait, one sweep, one hand. A ten-minute face with
// a one-minute tick pitch, the remainder always printed, and ending early stated as a quiet
// word rather than a failure.
//
// Three decisions the round made that this file must not quietly undo:
//
//   · **The sweep is wait-grey, never the kept accent.** A wait is neither good nor bad; the
//     blued/lume accent belongs to the answered truth alone. Colouring the timer "good" would
//     imply that finishing it is the score, when the point is that nothing is being scored.
//   · **Both truths are offered level at the end.** "It passed" and "Still there" sit as equal
//     controls — and "still there" is not a defeat, it is a hand-off to the 24-hour waiting
//     list, the same single mechanism used everywhere else.
//   · **An interrupted surf is interrupted, not lost.** If the app is killed mid-wait the
//     elapsed time is still on the clock; the screen names the fact and offers both recoveries.
//
// The timer never plays a sound. Its end is one soft haptic (`docs/FEEDBACK.md`).

struct UrgeSurfingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.scenePhase) private var scenePhase

    /// What is being waited out, when the surf was started from a specific temptation.
    var itemName: String?

    private static let totalSeconds: TimeInterval = 600

    /// Survives a kill: the surf is a wall-clock interval, so all that must persist is when it
    /// started. Anything derived from `Date` is then correct on the next launch by arithmetic
    /// rather than by bookkeeping.
    @AppStorage("urgeSurfStartedAt") private var startedAt: Double = 0

    @State private var phase: Phase = .idle
    @State private var showWaitingList = false

    /// The remaining-time reading is the one number this screen exists to show, so it scales
    /// with the user's setting and floors where it stops reading from arm's length.
    @ScaledMetric(relativeTo: .largeTitle) private var scaledReading: CGFloat = 52
    @ScaledMetric(relativeTo: .largeTitle) private var scaledReady: CGFloat = 64

    private enum Phase: Equatable {
        case idle
        case running
        case done
        /// The app was closed mid-surf and reopened with time still on the clock.
        case interrupted(remaining: TimeInterval)
    }

    private var isRegular: Bool { sizeClass == .regular }
    private var dialSize: CGFloat { isRegular ? 320 : 290 }

    var body: some View {
        NavigationStack {
            // One clock drives the arc, the hand and the remainder — a dial that disagrees with
            // its own number is worse than no dial. A one-second tick is honest here because
            // this screen IS the wait; everywhere else the app ticks once a minute.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let elapsed = elapsedSeconds(at: context.date)

                // The copy belongs TO the dial, so it sits a fixed gap beneath it and the two
                // travel together; only the space above the face and below the copy flexes.
                // An equal spacer on both sides of the copy — the first draft — floated it in
                // the middle of a void and read as an unrelated caption.
                VStack(spacing: 0) {
                    Spacer(minLength: DS.Spacing.md)

                    if let itemName {
                        Text(itemName)
                            .font(.subheadline)
                            .foregroundStyle(.inkSecondary)
                            .padding(.bottom, DS.Spacing.lg)
                    }

                    dial(elapsed: elapsed)
                        .padding(.bottom, DS.Spacing.xl)

                    copyBlock(elapsed: elapsed)

                    Spacer(minLength: DS.Spacing.xl)

                    controls(elapsed: elapsed)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, DS.Spacing.screenGutter)
                .background(Color.surfaceField)
                .onChange(of: Int(elapsed)) { _, seconds in
                    if phase == .running, TimeInterval(seconds) >= Self.totalSeconds {
                        complete()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Today") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(.inkSecondary)
                        .accessibilityIdentifier("urge_surfing_close")
                }
            }
            .sheet(isPresented: $showWaitingList) { WaitingListSheet() }
            .onAppear(perform: restoreIfInterrupted)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { restoreIfInterrupted() }
            }
        }
    }

    // MARK: - The face

    private func dial(elapsed: TimeInterval) -> some View {
        let progress = min(elapsed / Self.totalSeconds, 1)
        // The hand rests at the index when idle and again when the ten minutes are up: it
        // travels the wait and seats where it began.
        let handPosition: Double = phase == .running ? progress : 0

        return DialFace(
            size: dialSize,
            scale: .minutes,
            progress: progress,
            handPosition: handPosition,
            // Wait-grey, on purpose. See the note at the top of this file.
            arcColor: .stateWait
        ) {
            centreReading(elapsed: elapsed)
        }
        .opacity(isInterrupted ? 0.45 : 1)
        .animation(reduceMotion ? nil : DS.Anim.functional, value: isInterrupted)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dialAccessibilityLabel(elapsed: elapsed))
    }

    @ViewBuilder
    private func centreReading(elapsed: TimeInterval) -> some View {
        switch phase {
        case .idle:
            VStack(spacing: 2) {
                Text("10")
                    .font(.system(size: max(scaledReady, 48), weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.inkPrimary)
                Text("ready")
                    .font(.caption)
                    .foregroundStyle(.inkSecondary)
            }
        case .running:
            VStack(spacing: 2) {
                Text(Self.clock(Self.totalSeconds - elapsed))
                    .font(.system(size: max(scaledReading, 40), weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.inkPrimary)
                Text("left · started \(Self.startedClock(startedAt))")
                    .font(.caption2)
                    .foregroundStyle(.inkSecondary)
            }
        case .done:
            // The finished measurement stays ON the face. Leaving the centre empty and putting
            // "Ten minutes passed" below it — the first draft — emptied the one place the user
            // had been watching for ten minutes and made the closed ring look unfinished.
            VStack(spacing: 2) {
                Text(Self.clock(Self.totalSeconds))
                    .font(.system(size: max(scaledReading, 40), weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.inkPrimary)
                Text("passed")
                    .font(.caption)
                    .foregroundStyle(.inkSecondary)
            }
        case let .interrupted(remaining):
            VStack(spacing: 2) {
                Text(Self.clock(remaining))
                    .font(.system(size: max(scaledReading, 40), weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.inkPrimary)
                Text("left")
                    .font(.caption2)
                    .foregroundStyle(.inkSecondary)
            }
        }
    }

    // MARK: - Copy

    @ViewBuilder
    private func copyBlock(elapsed _: TimeInterval) -> some View {
        switch phase {
        case .idle:
            Text("Most urges pass. Ride this one out and see what is left of it.")
                .font(.body)
                .foregroundStyle(.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

        case .running:
            Text("Nothing to do. The wait is doing it.")
                .font(.body)
                .foregroundStyle(.inkSecondary)
                .multilineTextAlignment(.center)

        case .done:
            // One question, sitting as close to the two answers as the layout allows.
            Text("What is left of it?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.inkPrimary)

        case let .interrupted(remaining):
            VStack(spacing: DS.Spacing.sm) {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.stateWait)
                        .accessibilityHidden(true)
                    Text("Interrupted at \(Self.clock(remaining)).")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.inkPrimary)
                }
                Text("The app closed mid-surf. The wait was not wasted — pick it up or start over.")
                    .font(.footnote)
                    .foregroundStyle(.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private func controls(elapsed _: TimeInterval) -> some View {
        switch phase {
        case .idle:
            primaryButton("Begin ten minutes", identifier: "urge_begin") { begin() }
                .padding(.bottom, DS.Spacing.xxl)

        case .running:
            // Always present, never shouted: leaving early is a choice, not a failure.
            Button("End the surf") { endEarly() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.inkSecondary)
                .padding(.bottom, DS.Spacing.xxl)
                .accessibilityIdentifier("urge_end_early")

        case .done:
            // Both truths, LEVEL — and level means identical, not "one filled, one outlined".
            // The first draft made "It passed" the accent primary and "Still there" a plain
            // outline, which is the standard primary/secondary hierarchy and reads as the app
            // marking one honest answer as the correct one. Ten minutes of not-scoring would
            // end on a scoreboard. Same fill, same border, same type: only the words differ.
            VStack(spacing: DS.Spacing.sm) {
                levelButton("It passed — back to the day", identifier: "urge_passed") {
                    HapticManager.noBuySuccess()
                    clear()
                    dismiss()
                }

                levelButton("Still there — hold it 24 hours", identifier: "urge_still_there") {
                    clear()
                    showWaitingList = true
                }
            }
            .padding(.bottom, DS.Spacing.xxl)

        case let .interrupted(remaining):
            VStack(spacing: DS.Spacing.md) {
                primaryButton("Resume — \(Self.clock(remaining)) left", identifier: "urge_resume") {
                    phase = .running
                }

                Button("Start the ten minutes over") { begin() }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.inkSecondary)
                    .accessibilityIdentifier("urge_restart")
            }
            .padding(.bottom, DS.Spacing.xxl)
        }
    }

    private func primaryButton(
        _ title: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.inkOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(Color.accentKept))
        }
        .buttonStyle(.scale)
        .accessibilityIdentifier(identifier)
    }

    /// A choice the app refuses to rank: raised surface, hairline rim, primary ink. Used only in
    /// pairs — a single one of these would just be a weak primary.
    private func levelButton(
        _ title: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.inkPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule()
                        .fill(Color.surfaceWell)
                        .overlay(
                            Capsule().strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.hairline)
                        )
                )
        }
        .buttonStyle(.scale)
        .accessibilityIdentifier(identifier)
    }

    // MARK: - Lifecycle

    private func begin() {
        startedAt = Date.now.timeIntervalSince1970
        HapticManager.tap()
        withAnimation(reduceMotion ? nil : DS.Anim.functional) { phase = .running }
        Task { await scheduleCompletionNotification() }
    }

    private func endEarly() {
        clear()
        withAnimation(reduceMotion ? nil : DS.Anim.functional) { phase = .idle }
    }

    private func complete() {
        // One soft haptic, no sound — the end of a wait should not startle the person who
        // spent ten minutes calming down.
        HapticManager.success()
        cancelCompletionNotification()
        withAnimation(reduceMotion ? nil : DS.Anim.beat) { phase = .done }
    }

    /// How long a finished-but-unanswered surf stays claimable. Past this the app stops asking
    /// about a wait the person has plainly moved on from.
    private static let staleAfter: TimeInterval = 3600

    /// Reopening mid-surf: the elapsed time is still on the wall clock, so the surf resumes or
    /// completes rather than silently resetting.
    ///
    /// The completion is only offered while it is still THIS wait. `startedAt` survives in
    /// storage until the person answers, so without the staleness bound a surf begun on Tuesday
    /// greeted them on Friday with "Ten minutes passed. What is left of it?" — a question about
    /// an urge that ended three days ago, and a 10:00 reading that was never watched.
    private func restoreIfInterrupted() {
        guard startedAt > 0 else { return }
        let elapsed = Date.now.timeIntervalSince1970 - startedAt

        if elapsed >= Self.totalSeconds + Self.staleAfter {
            clear()
            phase = .idle
        } else if elapsed >= Self.totalSeconds {
            phase = .done
        } else if phase != .running {
            phase = .interrupted(remaining: Self.totalSeconds - elapsed)
        }
    }

    private func clear() {
        startedAt = 0
        cancelCompletionNotification()
    }

    private func elapsedSeconds(at date: Date) -> TimeInterval {
        guard startedAt > 0 else { return 0 }
        return max(date.timeIntervalSince1970 - startedAt, 0)
    }

    private var isInterrupted: Bool {
        if case .interrupted = phase { return true }
        return false
    }

    private func dialAccessibilityLabel(elapsed: TimeInterval) -> String {
        switch phase {
        case .idle: "Ten minutes, ready to begin"
        case .running: "\(Self.spoken(Self.totalSeconds - elapsed)) left"
        case .done: "Ten minutes passed"
        case let .interrupted(remaining): "Interrupted, \(Self.spoken(remaining)) left"
        }
    }

    // MARK: - Notification
    //
    // async/await rather than the completion-handler form: a closure handed to
    // `getNotificationSettings` runs on the framework's own queue, and reading `@MainActor`
    // state inside it is the crash class the simulator never reproduces
    // (`IOS/CLAUDE.md` — the surface the simulator cannot reach).

    private static let completionNotificationID = "urge_surfing_completion"

    private func scheduleCompletionNotification() async {
        let identifier = Self.completionNotificationID
        let delay = max(Self.totalSeconds - elapsedSeconds(at: .now), 1)

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "NoBuy"
        content.body = "Ten minutes passed. What is left of the urge?"
        content.sound = nil

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            AppLogger.notification.error("Failed to schedule urge completion: \(error.localizedDescription)")
        }
    }

    private func cancelCompletionNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.completionNotificationID])
    }

    // MARK: - Formatting

    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(Int(seconds.rounded()), 0)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    static func spoken(_ seconds: TimeInterval) -> String {
        let total = max(Int(seconds.rounded()), 0)
        let minutes = total / 60
        let secs = total % 60
        if minutes == 0 { return "\(secs) seconds" }
        return "\(minutes) minutes \(secs) seconds"
    }

    /// Wall-clock start, in the user's OWN clock convention. A forced `HH:mm` — the first draft —
    /// prints "13:24" to someone whose phone has said 1:24 PM all day; the app is English-only,
    /// but 12-vs-24-hour is a device setting, not a language.
    private static func startedClock(_ timestamp: Double) -> String {
        Date(timeIntervalSince1970: timestamp).formatted(date: .omitted, time: .shortened)
    }
}

#Preview("Idle") {
    UrgeSurfingView(itemName: "the grinder — 220")
}
