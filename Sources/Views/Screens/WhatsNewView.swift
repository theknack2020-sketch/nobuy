import SwiftUI

// MARK: - What changed (Escapement, v2.0.0)
//
// Shown once, to someone who already uses the app, at the moment the app they know looks
// different. So it does two jobs and no others: say what changed, and — because this release
// changes how NoBuy is paid for — tell the people who already paid that nothing was taken away.
//
// That last row is the reason this screen is not decoration. Sixty people bought the one-time
// unlock. A subscription migration that does not say "yours, permanently, in writing" reads as
// a bait-and-switch even when the code is honest, and the code being honest is not the part the
// user can see.
//
// One list, no gradient, no confetti, no scale-in hero: the same instrument voice as the rest
// of the app. A release note that shouts is a release note nobody believes.

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Change: Identifiable {
        let id = UUID()
        let glyph: String
        let title: String
        let detail: String
    }

    /// Written for THIS release. A stale list is worse than none: the v1.2.0 notes survived the
    /// version bump into a 2.0.0 build during development and announced iPad support to people
    /// who had it for a year.
    private let changes: [Change] = [
        Change(
            glyph: "circle.dotted",
            title: "A new face",
            detail: "The day, the record and both interventions redrawn as one instrument — the day on a dial, the run as a bar you can read at a glance."
        ),
        Change(
            glyph: "square.grid.2x2",
            title: "A widget",
            detail: "Answer the day from the Home Screen without opening NoBuy, and read the run from the Lock Screen."
        ),
        Change(
            glyph: "list.bullet",
            title: "The checklist is yours",
            detail: "Add your own questions before you buy, remove the ones that do not fit, and put them in your own order."
        ),
        Change(
            glyph: "checkmark.seal",
            title: "Pro is a subscription now",
            detail: "If you already bought the one-time unlock, it stays yours permanently — nothing to re-buy, no trial, no expiry."
        ),
    ]

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("What changed")
                            .font(.largeTitle.weight(.semibold))
                            .foregroundStyle(.inkPrimary)
                        Text("Version \(version)")
                            .font(.subheadline)
                            .foregroundStyle(.inkSecondary)
                    }
                    .padding(.top, DS.Spacing.lg)
                    .accessibilityElement(children: .combine)

                    VStack(spacing: DS.Spacing.md) {
                        ForEach(changes) { change in
                            row(change)
                        }
                    }

                    Spacer(minLength: DS.Spacing.xl)

                    Button {
                        HapticManager.tap()
                        dismiss()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(Color.inkOnAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Capsule().fill(Color.accentKept))
                    }
                    .buttonStyle(.scale)
                    .accessibilityIdentifier("whats_new_continue")
                    .padding(.bottom, DS.Spacing.xxl)
                }
                .padding(.horizontal, DS.Spacing.screenGutter)
            }
            .background(Color.surfaceField)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(.subheadline)
                        .accessibilityIdentifier("whats_new_close")
                }
            }
        }
    }

    private func row(_ change: Change) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            Image(systemName: change.glyph)
                .font(.footnote)
                .foregroundStyle(.stateWait)
                .frame(width: 22)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(change.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.inkPrimary)
                Text(change.detail)
                    .font(.footnote)
                    .foregroundStyle(.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(Color.surfaceWell)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.hairline)
                )
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WhatsNewView()
}
