import SwiftUI

struct ChallengeSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onStart: (Int) -> Void

    @State private var selectedDuration: Int? = nil
    @State private var customDays: String = ""
    @State private var appeared = false
    @State private var shakeCustomField = false
    @State private var validationError: String? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    private let presets: [(days: Int, label: String, icon: String)] = [
        (7, "7 Days", "7.circle.fill"),
        (14, "14 Days", "14.circle.fill"),
        (30, "30 Days", "30.circle.fill"),
        (60, "60 Days", "60.circle.fill"),
        (100, "100 Days", "circle.badge.checkmark.fill"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.xxl) {
                // Header with gradient
                VStack(spacing: DS.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(
                                .accentKept.opacity(0.12)
                            )
                            .frame(width: 72, height: 72)

                        Image(systemName: "flame")
                            .font(Font.adaptiveDisplay(size: 40, isRegular: isRegular))
                            .foregroundStyle(
                                .accentKept
                            )
                    }

                    Text("Challenge Duration")
                        .font(Font.adaptiveDisplay(size: 22, weight: .semibold, isRegular: isRegular))

                    Text("How many no-spend days are you aiming for?")
                        .font(.subheadline)
                        .foregroundStyle(.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.xl)
                }
                .padding(.top, DS.Spacing.lg)

                // Preset options
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: DS.Spacing.md) {
                    ForEach(presets, id: \.days) { preset in
                        Button {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedDuration = preset.days
                                customDays = ""
                                validationError = nil
                            }
                            HapticManager.tap()
                            SoundManager.playIfEnabled(.tap)
                        } label: {
                            VStack(spacing: DS.Spacing.sm) {
                                Text("\(preset.days)")
                                    .font(Font.adaptiveDisplay(size: 28, weight: .semibold, isRegular: isRegular))
                                    .foregroundStyle(selectedDuration == preset.days ? Color.inkOnAccent : .accentKept)
                                Text("days")
                                    .font(.caption)
                                    .foregroundStyle(selectedDuration == preset.days ? Color.inkOnAccent.opacity(0.8) : .inkSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.md)
                                    .fill(selectedDuration == preset.days
                                        ? AnyShapeStyle(.accentKept)
                                        : AnyShapeStyle(Color.surfaceDial))
                            )

                        }
                        .buttonStyle(.scale)
                    }

                    // Custom option
                    Button {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7)) {
                            selectedDuration = -1 // Custom marker
                            validationError = nil
                        }
                        HapticManager.tap()
                        SoundManager.playIfEnabled(.tap)
                    } label: {
                        VStack(spacing: DS.Spacing.sm) {
                            Image(systemName: "pencil.circle.fill")
                                .font(Font.adaptiveDisplay(size: 24, isRegular: isRegular))
                                .foregroundStyle(selectedDuration == -1 ? Color.inkOnAccent : .accentKept)
                                .accessibilityHidden(true)
                            Text("Custom")
                                .font(.caption)
                                .foregroundStyle(selectedDuration == -1 ? Color.inkOnAccent.opacity(0.8) : .inkSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(selectedDuration == -1
                                    ? AnyShapeStyle(.accentKept)
                                    : AnyShapeStyle(Color.surfaceDial))
                        )

                    }
                    .buttonStyle(.scale)
                }
                .padding(.horizontal, DS.Spacing.xl)

                // Custom input with validation
                if selectedDuration == -1 {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        HStack(spacing: DS.Spacing.md) {
                            TextField(
                                "Number of days",
                                text: $customDays
                            )
                            .keyboardType(.numberPad)
                            .font(Font.adaptiveTitle3(isRegular: isRegular).weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, DS.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.md)
                                    .fill(Color.surfaceDial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DS.Radius.md)
                                            .stroke(validationError != nil ? Color.accentSpentText.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                    )
                            )

                            .offset(x: shakeCustomField ? -8 : 0)
                            .onChange(of: customDays) {
                                validateCustomDays()
                            }

                            Text("days")
                                .font(.headline)
                                .foregroundStyle(.inkSecondary)
                        }

                        // Inline validation error
                        if let error = validationError {
                            HStack(spacing: DS.Spacing.xs) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.accentSpentText)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.accentSpentText)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, DS.Spacing.xl)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                // Start button
                Button {
                    if selectedDuration == -1, !validateAndShake() {
                        return
                    }
                    let duration = resolvedDuration
                    guard duration > 0 else { return }
                    HapticManager.success()
                    SoundManager.playIfEnabled(.save)
                    onStart(duration)
                    dismiss()
                } label: {
                    Text("Start Challenge")
                        .font(.headline)
                        .foregroundStyle(Color.inkOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.lg)
                                .fill(
                                    isValid
                                        ? AnyShapeStyle(.accentKept)
                                        : AnyShapeStyle(Color.accentKept.opacity(0.4))
                                )
                        )

                }
                .buttonStyle(.scale)
                .disabled(!isValid && selectedDuration != -1)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.bottom, DS.Spacing.lg)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        HapticManager.tap()
                        dismiss()
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Validation

    private func validateCustomDays() {
        guard selectedDuration == -1 else {
            validationError = nil
            return
        }

        if customDays.isEmpty {
            validationError = nil
            return
        }

        guard let value = Int(customDays) else {
            validationError = L10n.validationNumberOnly
            return
        }

        if value < 1 {
            validationError = L10n.validationMinDays
        } else if value > 365 {
            validationError = L10n.validationMaxDays
        } else {
            validationError = nil
        }
    }

    /// Validates custom input and triggers shake on failure. Returns true if valid.
    private func validateAndShake() -> Bool {
        guard selectedDuration == -1 else { return true }

        if customDays.isEmpty {
            validationError = L10n.validationRequired
            triggerShake()
            return false
        }

        guard let value = Int(customDays), value >= 1, value <= 365 else {
            validateCustomDays()
            triggerShake()
            return false
        }

        return true
    }

    private func triggerShake() {
        HapticManager.warning()
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) {
            shakeCustomField = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) {
                shakeCustomField = false
            }
        }
    }

    private var resolvedDuration: Int {
        if let selected = selectedDuration, selected > 0 {
            return selected
        }
        if selectedDuration == -1, let custom = Int(customDays), custom > 0, custom <= 365 {
            return custom
        }
        return 0
    }

    private var isValid: Bool {
        resolvedDuration > 0 && validationError == nil
    }
}

#Preview {
    ChallengeSetupSheet { days in
        AppLogger.general.debug("Challenge selected: \(days) days")
    }
}
