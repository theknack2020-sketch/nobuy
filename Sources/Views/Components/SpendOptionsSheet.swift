import SwiftData
import SwiftUI

struct SpendOptionsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: HomeViewModel
    let records: [DayRecord]
    @State private var appeared = false
    @State private var showImpulseChecklist = false
    @State private var spendAmount: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var amountFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.xl) {
                // Header
                VStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "questionmark.circle")
                        .font(Font.adaptiveDisplay(size: 32, isRegular: isRegular))
                        .foregroundStyle(
                            .inkSecondary
                        )

                    Text(L10n.spendTypeQuestion)
                        .font(.headline)
                }
                .padding(.top, DS.Spacing.md)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7), value: appeared)

                // Essential spend option
                Button {
                    HapticManager.tap()
                    SoundManager.playIfEnabled(.save)
                    viewModel.markSpent(context: modelContext, mandatoryOnly: true, allRecords: records)
                    dismiss()
                } label: {
                    HStack(spacing: DS.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.stateWait.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "building.columns")
                                .font(.title3)
                                .foregroundStyle(.stateWait)
                                .accessibilityHidden(true)
                        }

                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text(L10n.mandatorySpend)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.inkPrimary)
                            Text(L10n.mandatoryDesc)
                                .font(.caption)
                                .foregroundStyle(.inkSecondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark.shield")
                            .font(.title3)
                            .foregroundStyle(.accentKept)
                    }
                    .padding(DS.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(Color.stateWaitWash)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.md)
                                    .stroke(Color.stateWait.opacity(0.2), lineWidth: 1)
                            )
                    )

                }
                .buttonStyle(.scale)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7).delay(0.05), value: appeared)

                // Discretionary spend option
                Button {
                    HapticManager.warning()
                    SoundManager.playIfEnabled(.save)
                    let amount = Double(spendAmount.replacingOccurrences(of: ",", with: "."))
                    viewModel.markSpent(context: modelContext, mandatoryOnly: false, allRecords: records, amount: amount)
                    dismiss()
                } label: {
                    HStack(spacing: DS.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.accentSpentText.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "cart")
                                .font(.title3)
                                .foregroundStyle(.accentSpentText)
                        }

                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text(L10n.discretionarySpend)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.inkPrimary)
                            Text(L10n.discretionaryDesc)
                                .font(.caption)
                                .foregroundStyle(.inkSecondary)
                        }

                        Spacer()

                        Image(systemName: "exclamationmark.triangle")
                            .font(.title3)
                            .foregroundStyle(.accentSpentText.opacity(0.7))
                    }
                    .padding(DS.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(Color.accentSpentWash)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.md)
                                    .stroke(Color.accentSpentText.opacity(0.15), lineWidth: 1)
                            )
                    )

                }
                .buttonStyle(.scale)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: appeared)

                // Optional amount input
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "dollarsign.circle")
                        .font(.body)
                        .foregroundStyle(.inkSecondary)
                    TextField(L10n.spendAmountPlaceholder, text: $spendAmount)
                        .keyboardType(.decimalPad)
                        .focused($amountFocused)
                        .font(.subheadline)
                }
                .padding(DS.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(Color.surfaceDial)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.sm)
                                .stroke(Color.inkSecondary.opacity(0.2), lineWidth: 1)
                        )
                )

                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7).delay(0.15), value: appeared)

                // Impulse checklist nudge
                Button {
                    HapticManager.tap()
                    SoundManager.playIfEnabled(.tap)
                    showImpulseChecklist = true
                } label: {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "checklist")
                            .font(.caption)
                            .foregroundStyle(.accentKept)
                        Text("Wait — try the checklist first")
                            .font(.caption)
                            .foregroundStyle(.accentKept)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, DS.Spacing.sm)
                    .padding(.horizontal, DS.Spacing.md)
                    .background(
                        Capsule()
                            .fill(Color.accentKeptWash)
                    )
                }
                .buttonStyle(.scale)
                .opacity(appeared ? 1 : 0)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7).delay(0.2), value: appeared)

                Spacer()
            }
            .padding(.horizontal, DS.Spacing.xl)
            .background(DS.Gradient.glow.opacity(0.3).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        HapticManager.tap()
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { amountFocused = false }
                }
            }
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(DS.Anim.stagger)) {
                        appeared = true
                    }
                }
            }
            .alert(L10n.errorGenericTitle, isPresented: $showError) {
                Button(L10n.errorOK) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showImpulseChecklist) {
                ImpulseChecklistScreen {
                    // User decided not to buy — dismiss the spend sheet too
                    dismiss()
                }
            }
        }
    }
}
