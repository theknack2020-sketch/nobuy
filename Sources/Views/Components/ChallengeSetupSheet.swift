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
                                RadialGradient(
                                    colors: [.noBuyGreen.opacity(0.2), .noBuyGreen.opacity(0.02)],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 72, height: 72)

                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.noBuyGreen, .green.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("Challenge Duration")
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    Text("How many no-spend days are you aiming for?")
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
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
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(selectedDuration == preset.days ? .white : .noBuyGreen)
                                Text("days")
                                    .font(.caption)
                                    .foregroundStyle(selectedDuration == preset.days ? .white.opacity(0.8) : .textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.md)
                                    .fill(selectedDuration == preset.days
                                        ? AnyShapeStyle(LinearGradient(colors: [.noBuyGreen, .noBuyGreen.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        : AnyShapeStyle(Color.surfaceSecondary))
                            )
                            .shadow(color: selectedDuration == preset.days ? .noBuyGreen.opacity(0.25) : .black.opacity(0.05), radius: selectedDuration == preset.days ? 8 : 4, x: 0, y: 3)
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
                                .font(.system(size: 24))
                                .foregroundStyle(selectedDuration == -1 ? .white : .noBuyGreen)
                            Text("Custom")
                                .font(.caption)
                                .foregroundStyle(selectedDuration == -1 ? .white.opacity(0.8) : .textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(selectedDuration == -1
                                    ? AnyShapeStyle(LinearGradient(colors: [.noBuyGreen, .noBuyGreen.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    : AnyShapeStyle(Color.surfaceSecondary))
                        )
                        .shadow(color: selectedDuration == -1 ? .noBuyGreen.opacity(0.25) : .black.opacity(0.05), radius: selectedDuration == -1 ? 8 : 4, x: 0, y: 3)
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
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, DS.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.md)
                                    .fill(Color.surfaceSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DS.Radius.md)
                                            .stroke(validationError != nil ? Color.spendRed.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                    )
                            )
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                            .offset(x: shakeCustomField ? -8 : 0)
                            .onChange(of: customDays) {
                                validateCustomDays()
                            }

                            Text("days")
                                .font(.headline)
                                .foregroundStyle(.textSecondary)
                        }

                        // Inline validation error
                        if let error = validationError {
                            HStack(spacing: DS.Spacing.xs) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.spendRed)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.spendRed)
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
                    if selectedDuration == -1 && !validateAndShake() {
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
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.lg)
                                .fill(
                                    isValid
                                        ? AnyShapeStyle(LinearGradient(colors: [.noBuyGreen, .noBuyGreen.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                                        : AnyShapeStyle(Color.noBuyGreen.opacity(0.4))
                                )
                        )
                        .shadow(color: isValid ? .noBuyGreen.opacity(0.3) : .clear, radius: 12, x: 0, y: 6)
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
