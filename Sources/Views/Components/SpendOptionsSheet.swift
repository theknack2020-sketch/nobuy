import SwiftUI
import SwiftData

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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.xl) {
                // Header
                VStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.textSecondary, .textTertiary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
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
                                .fill(Color.mandatoryAmber.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "building.columns.fill")
                                .font(.title3)
                                .foregroundStyle(.mandatoryAmber)
                        }

                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text(L10n.mandatorySpend)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.textPrimary)
                            Text(L10n.mandatoryDesc)
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark.shield.fill")
                            .font(.title3)
                            .foregroundStyle(.noBuyGreen)
                    }
                    .padding(DS.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(Color.mandatoryAmberLight)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.md)
                                    .stroke(Color.mandatoryAmber.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(color: .mandatoryAmber.opacity(0.1), radius: 4, x: 0, y: 2)
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
                                .fill(Color.spendRed.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "cart.fill")
                                .font(.title3)
                                .foregroundStyle(.spendRed)
                        }

                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text(L10n.discretionarySpend)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.textPrimary)
                            Text(L10n.discretionaryDesc)
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3)
                            .foregroundStyle(.spendRed.opacity(0.7))
                    }
                    .padding(DS.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(Color.spendRedLight)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.md)
                                    .stroke(Color.spendRed.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .shadow(color: .spendRed.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.scale)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: appeared)

                // Optional amount input
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.body)
                        .foregroundStyle(.textTertiary)
                    TextField(L10n.spendAmountPlaceholder, text: $spendAmount)
                        .keyboardType(.decimalPad)
                        .font(.subheadline)
                }
                .padding(DS.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(Color.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.sm)
                                .stroke(Color.textTertiary.opacity(0.2), lineWidth: 1)
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
                            .foregroundStyle(.noBuyGreen)
                        Text("Wait — try the checklist first")
                            .font(.caption)
                            .foregroundStyle(.noBuyGreen)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, DS.Spacing.sm)
                    .padding(.horizontal, DS.Spacing.md)
                    .background(
                        Capsule()
                            .fill(Color.noBuyGreenLight)
                    )
                }
                .buttonStyle(.scale)
                .opacity(appeared ? 1 : 0)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7).delay(0.2), value: appeared)

                Spacer()
            }
            .padding(.horizontal, DS.Spacing.xl)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        HapticManager.tap()
                        dismiss()
                    }
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
                Button(L10n.errorOK) { }
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
