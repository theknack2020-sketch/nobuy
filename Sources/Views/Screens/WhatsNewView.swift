import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    @State private var appeared = false

    private struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        let color: Color
    }

    private let features: [Feature] = [
        Feature(
            icon: "ipad.landscape",
            title: "NoBuy on iPad",
            description: "Full iPad support with a sidebar layout and every orientation.",
            color: .blue
        ),
        Feature(
            icon: "lock.shield.fill",
            title: "Private by Design",
            description: "All analytics code removed. Your data never leaves your device.",
            color: .noBuyGreen
        ),
        Feature(
            icon: "star.bubble",
            title: "A Better Way to Give Feedback",
            description: "Tell us how we're doing — or email us privately, right from the app.",
            color: .mandatoryAmber
        ),
        Feature(
            icon: "sparkles",
            title: "Faster & Lighter",
            description: "Third-party code removed for a quicker launch and a smaller app.",
            color: .purple
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.xxl) {
                    Spacer().frame(height: DS.Spacing.lg)

                    // Hero
                    VStack(spacing: DS.Spacing.md) {
                        Text("🎉")
                            .font(.system(size: 56))
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.5)

                        Text("What's New in NoBuy")
                            .font(.title.bold())
                            .foregroundStyle(.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                            .font(.subheadline)
                            .foregroundStyle(.textSecondary)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)

                    // Features
                    VStack(spacing: DS.Spacing.lg) {
                        ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                            featureRow(feature)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(
                                    reduceMotion ? nil : DS.Anim.normal.delay(Double(index) * DS.Anim.stagger + 0.2),
                                    value: appeared
                                )
                        }
                    }
                    .padding(.horizontal, DS.Spacing.xl)

                    Spacer().frame(height: DS.Spacing.lg)

                    // CTA
                    Button {
                        HapticManager.tap()
                        dismiss()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.lg)
                                    .fill(
                                        LinearGradient(
                                            colors: [.noBuyGreen, .noBuyGreen.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: .noBuyGreen.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.bottom, DS.Spacing.xxxl)
                }
            }
            .background(Color.surfacePrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.textTertiary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(DS.Anim.normal) {
                        appeared = true
                    }
                }
            }
        }
    }

    private func featureRow(_ feature: Feature) -> some View {
        HStack(spacing: DS.Spacing.lg) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundStyle(feature.color)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(feature.color.opacity(0.12))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.textPrimary)

                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(DS.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(Color.surfaceSecondary)
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WhatsNewView()
}
