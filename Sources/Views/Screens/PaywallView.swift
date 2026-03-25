import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let store: StoreService

    @State private var showCloseButton = false
    @State private var showCelebration = false
    @State private var pulseGlow = false
    @State private var tableAppeared = false
    @State private var ctaAppeared = false
    @State private var isLoadingProduct = true
    @State private var socialProofCount = 2847 // Simulated social proof

    // MARK: - Feature Row Model

    private struct FeatureRow: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let freeValue: FeatureValue
        let proValue: FeatureValue
    }

    private enum FeatureValue {
        case check
        case cross
        case text(String)

        var isAvailable: Bool {
            switch self {
            case .cross: return false
            default: return true
            }
        }
    }

    private let features: [FeatureRow] = [
        FeatureRow(name: "Daily Logging", icon: "pencil.circle", freeValue: .check, proValue: .check),
        FeatureRow(name: "Streak Tracking", icon: "flame", freeValue: .check, proValue: .check),
        FeatureRow(name: "Basic Stats", icon: "chart.bar", freeValue: .check, proValue: .check),
        FeatureRow(name: "Essential Categories", icon: "folder", freeValue: .text("3"), proValue: .text("∞")),
        FeatureRow(name: "Monthly Chart", icon: "chart.line.uptrend.xyaxis", freeValue: .cross, proValue: .check),
        FeatureRow(name: "Weekly Distribution", icon: "chart.pie", freeValue: .cross, proValue: .check),
        FeatureRow(name: "Savings Estimate", icon: "dollarsign.circle", freeValue: .cross, proValue: .check),
        FeatureRow(name: "Streak History", icon: "clock.arrow.circlepath", freeValue: .cross, proValue: .check),
        FeatureRow(name: "CSV Export", icon: "arrow.down.doc", freeValue: .cross, proValue: .check),
        FeatureRow(name: "Enhanced Sharing", icon: "square.and.arrow.up", freeValue: .cross, proValue: .check),
        FeatureRow(name: "Unlimited Freezes", icon: "shield", freeValue: .text("1/mo"), proValue: .text("∞")),
        FeatureRow(name: "Challenges", icon: "trophy", freeValue: .cross, proValue: .check),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                backgroundGradient

                // Main scrollable content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: DS.Spacing.huge + DS.Spacing.md)

                        // Hero crown icon
                        heroIcon
                            .padding(.bottom, DS.Spacing.xxl)

                        // Bold headline
                        Text(L10n.paywallTitle)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text(L10n.paywallSubtitle)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.top, DS.Spacing.xs)

                        // Price anchoring pill
                        priceAnchorPill
                            .padding(.top, DS.Spacing.lg)

                        // Social proof
                        socialProof
                            .padding(.top, DS.Spacing.md)

                        // Feature comparison table
                        comparisonTable
                            .padding(.top, DS.Spacing.xxl)
                            .opacity(tableAppeared ? 1 : 0)
                            .offset(y: tableAppeared ? 0 : 20)

                        // Trust badges
                        trustBadges
                            .padding(.top, DS.Spacing.xxl)

                        // CTA section
                        ctaSection
                            .padding(.top, DS.Spacing.xxl)
                            .padding(.bottom, DS.Spacing.huge)
                            .opacity(ctaAppeared ? 1 : 0)
                            .offset(y: ctaAppeared ? 0 : 16)
                    }
                    .padding(.horizontal, DS.Spacing.xl)
                }
                .scrollDismissesKeyboard(.interactively)
                .opacity(showCelebration ? 0 : 1)

                // Celebration overlay
                if showCelebration {
                    celebrationOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if showCloseButton && !isPurchasing {
                        Button {
                            store.trackPaywallDismissed()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .transition(.opacity)
                        .accessibilityLabel("Close paywall")
                        .accessibilityIdentifier("paywall_close")
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .interactiveDismissDisabled(isPurchasing)
            .onAppear { onAppearSetup() }
            .onChange(of: store.purchaseState) { _, newValue in
                if case .purchased = newValue {
                    showPurchaseCelebration()
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.noBuyGreen.opacity(0.35),
                Color.black.opacity(0.92),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: - Hero Icon

    private var heroIcon: some View {
        ZStack {
            // Outer pulsing glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.noBuyGreen.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(pulseGlow ? 1.15 : 0.95)
                .opacity(pulseGlow ? 0.5 : 0.8)

            // Inner circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.noBuyGreen, Color.noBuyGreen.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)
                .shadow(color: .noBuyGreen.opacity(0.5), radius: 20, y: 4)

            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Price Anchor

    private var priceAnchorPill: some View {
        Text("☕ \(L10n.paywallPriceAnchor)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.noBuyGreen)
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.sm)
            .background(
                Capsule()
                    .fill(Color.noBuyGreen.opacity(0.15))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.noBuyGreen.opacity(0.3), lineWidth: 1)
                    )
            )
    }

    // MARK: - Social Proof

    private var socialProof: some View {
        HStack(spacing: DS.Spacing.xs) {
            // Mini avatar stack
            HStack(spacing: -6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(
                            [Color.blue, Color.purple, Color.orange][i].opacity(0.8)
                        )
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .accessibilityHidden(true)

            Text("Join \(socialProofCount.formatted()) mindful spenders")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Join \(socialProofCount.formatted()) mindful spenders")
    }

    // MARK: - Comparison Table

    private var comparisonTable: some View {
        VStack(spacing: 0) {
            // Table header
            HStack {
                Text("Feature")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Free")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 52)

                Text("Pro")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.noBuyGreen)
                    .frame(width: 52)
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.md)

            // Rows
            ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                VStack(spacing: 0) {
                    if index > 0 {
                        Divider()
                            .background(Color.white.opacity(0.06))
                    }

                    HStack {
                        HStack(spacing: DS.Spacing.sm) {
                            Image(systemName: feature.icon)
                                .font(.caption)
                                .foregroundStyle(feature.freeValue.isAvailable ? .white.opacity(0.6) : .noBuyGreen)
                                .frame(width: 18)

                            Text(feature.name)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        featureValueView(feature.freeValue, isPro: false)
                            .frame(width: 52)

                        featureValueView(feature.proValue, isPro: true)
                            .frame(width: 52)
                    }
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.vertical, DS.Spacing.md)
                    .background(
                        !feature.freeValue.isAvailable
                            ? Color.noBuyGreen.opacity(0.04)
                            : Color.clear
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.lg)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
    }

    @ViewBuilder
    private func featureValueView(_ value: FeatureValue, isPro: Bool) -> some View {
        switch value {
        case .check:
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(isPro ? .noBuyGreen : .white.opacity(0.5))
        case .cross:
            Image(systemName: "minus")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.2))
        case .text(let text):
            Text(text)
                .font(.caption.weight(.bold))
                .foregroundStyle(isPro ? .noBuyGreen : .white.opacity(0.5))
        }
    }

    // MARK: - Trust Badges

    private var trustBadges: some View {
        HStack(spacing: DS.Spacing.lg) {
            trustBadge(icon: "creditcard.and.123", text: "One-Time\nPurchase")
            trustBadge(icon: "arrow.triangle.2.circlepath.circle", text: "No\nSubscription")
            trustBadge(icon: "hand.raised.slash", text: "No Ads\nEver")
        }
    }

    private func trustBadge(icon: String, text: String) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.noBuyGreen)
                .accessibilityHidden(true)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: DS.Spacing.md) {
            // Large CTA button
            if store.product != nil {
                // Product loaded — show purchase button
                Button {
                    Task { await store.purchase() }
                } label: {
                    Group {
                        if case .purchasing = store.purchaseState {
                            ProgressView()
                                .tint(.white)
                        } else {
                            HStack(spacing: DS.Spacing.sm) {
                                Image(systemName: "crown.fill")
                                    .font(.callout)
                                Text(L10n.paywallUnlock(store.product!.displayPrice))
                                    .font(.headline)
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [Color.noBuyGreen, Color.noBuyGreen.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .noBuyGreen.opacity(0.4), radius: 16, y: 6)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isPurchasing)
                .accessibilityLabel("Unlock Pro for \(store.product!.displayPrice)")
                .accessibilityHint("Double tap to purchase NoBuy Pro")
                .accessibilityIdentifier("paywall_purchase_button")
            } else if isLoadingProduct {
                // Still loading product — show spinner with timeout message
                VStack(spacing: DS.Spacing.sm) {
                    ProgressView()
                        .tint(.white)
                        .frame(height: 58)
                    Text("Loading price…")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            } else {
                // Product failed to load — show retry
                VStack(spacing: DS.Spacing.md) {
                    Text("Unable to load product information.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Button {
                        isLoadingProduct = true
                        Task {
                            await store.loadProducts()
                            isLoadingProduct = false
                        }
                    } label: {
                        HStack(spacing: DS.Spacing.sm) {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.lg)
                                .fill(Color.white.opacity(0.15))
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("Retry loading product")
                }
            }

            // Restore purchases link
            Button(L10n.paywallRestore) {
                Task { await store.restore() }
            }
            .font(.callout)
            .foregroundStyle(.white.opacity(0.4))
            .accessibilityLabel("Restore purchases")
            .accessibilityHint("Double tap to restore previous purchases")

            // Error message
            if case .failed(let message) = store.purchaseState {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.spendRed)
                    .transition(.opacity)
            }

            // Restore feedback
            if store.restoreState == .success {
                Text(L10n.paywallRestoreSuccess)
                    .font(.caption)
                    .foregroundStyle(.noBuyGreen)
                    .transition(.opacity)
            } else if store.restoreState == .failed {
                Text(L10n.paywallRestoreFail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Celebration

    private var celebrationOverlay: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: DS.Spacing.xl) {
                Spacer()

                // Confetti
                ConfettiView()

                ZStack {
                    Circle()
                        .fill(Color.noBuyGreen.opacity(0.15))
                        .frame(width: 140, height: 140)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.noBuyGreen)
                        .symbolEffect(.bounce, value: showCelebration)
                }

                Text(L10n.paywallWelcome)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(L10n.paywallWelcomeDetail)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()
            }
        }
    }

    // MARK: - Actions

    private func onAppearSetup() {
        store.trackPaywallShown()

        // Reset purchase state on re-open
        if case .failed = store.purchaseState {
            store.purchaseState = .idle
        }

        // Load/retry product if nil
        if store.product == nil {
            isLoadingProduct = true
            Task {
                await store.loadProducts()
                isLoadingProduct = false
            }
        } else {
            isLoadingProduct = false
        }

        // Timeout for product loading — stop spinner after 10s
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if store.product == nil {
                isLoadingProduct = false
            }
        }

        // Delayed close button (2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(reduceMotion ? nil : .easeIn(duration: 0.3)) {
                showCloseButton = true
            }
        }

        // Pulsing glow animation
        if !reduceMotion {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                pulseGlow = true
            }
        }

        // Staggered table appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(reduceMotion ? nil : DS.Anim.normal) {
                tableAppeared = true
            }
        }

        // CTA appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(reduceMotion ? nil : DS.Anim.normal) {
                ctaAppeared = true
            }
        }
    }

    private func showPurchaseCelebration() {
        HapticManager.notification(.success)
        SoundManager.playIfEnabled(.milestone)
        withAnimation(reduceMotion ? nil : DS.Anim.normal) {
            showCelebration = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            dismiss()
        }
    }

    // MARK: - Helpers

    private var isPurchasing: Bool {
        if case .purchasing = store.purchaseState { return true }
        return false
    }
}

#Preview {
    PaywallView(store: .shared)
}
