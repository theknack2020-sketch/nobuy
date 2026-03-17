import SwiftUI

struct OnboardingScreen: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, description: String, color: Color)] = [
        ("checkmark.circle.fill", L10n.onboardingTitle1, L10n.onboardingDesc1, .noBuyGreen),
        ("flame.fill", L10n.onboardingTitle2, L10n.onboardingDesc2, .orange),
        ("calendar.badge.checkmark", L10n.onboardingTitle3, L10n.onboardingDesc3, .noBuyGreen),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    onboardingPage(index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.noBuyGreen : Color.textTertiary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.3 : 1.0)
                        .animation(.spring(duration: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 32)

            // Action button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasCompletedOnboarding = true
                }
                HapticManager.impact(.light)
            } label: {
                Text(currentPage < pages.count - 1 ? L10n.next : L10n.getStarted)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.noBuyGreen)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Skip
            if currentPage < pages.count - 1 {
                Button {
                    hasCompletedOnboarding = true
                } label: {
                    Text("Atla")
                        .font(.subheadline)
                        .foregroundStyle(.textTertiary)
                }
                .padding(.bottom, 24)
            } else {
                Spacer().frame(height: 48)
            }
        }
        .background(Color.surfacePrimary)
    }

    private func onboardingPage(_ index: Int) -> some View {
        let page = pages[index]
        return VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(page.color)
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingScreen()
}
