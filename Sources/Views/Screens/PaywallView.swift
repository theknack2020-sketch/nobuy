import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let store: StoreService

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.noBuyGreen.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.noBuyGreen)
                }
                .padding(.bottom, 24)

                // Title
                Text(L10n.paywallTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(L10n.paywallSubtitle)
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    featureRow(icon: "chart.line.uptrend.xyaxis", text: L10n.paywallFeature1)
                    featureRow(icon: "square.and.arrow.up.fill", text: L10n.paywallFeature2)
                    featureRow(icon: "folder.fill.badge.plus", text: L10n.paywallFeature3)
                    featureRow(icon: "heart.fill", text: L10n.paywallFeature4)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 32)

                Spacer()

                // Purchase button
                VStack(spacing: 12) {
                    Button {
                        Task { await store.purchase() }
                    } label: {
                        Group {
                            if case .purchasing = store.purchaseState {
                                ProgressView()
                                    .tint(.white)
                            } else if let product = store.product {
                                Text(L10n.paywallUnlock(product.displayPrice))
                                    .font(.headline)
                            } else {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.noBuyGreen)
                        )
                    }
                    .disabled(store.product == nil || isPurchasing)

                    Button(L10n.paywallRestore) {
                        Task { await store.restore() }
                    }
                    .font(.callout)
                    .foregroundStyle(.textSecondary)

                    if case .failed(let message) = store.purchaseState {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.spendRed)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color.surfacePrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.textTertiary)
                    }
                }
            }
            .onChange(of: store.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private var isPurchasing: Bool {
        if case .purchasing = store.purchaseState { return true }
        return false
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.noBuyGreen)
                .frame(width: 28)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    PaywallView(store: .shared)
}
