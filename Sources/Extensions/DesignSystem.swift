import SwiftUI

// MARK: - Design System Constants

enum DS {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 40
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Anim {
        static let quick = Animation.spring(duration: 0.25, bounce: 0.2)
        static let normal = Animation.spring(duration: 0.4, bounce: 0.25)
        static let slow = Animation.spring(duration: 0.6, bounce: 0.3)
        static let stagger: Double = 0.05
    }

    // MARK: - Gradient Presets

    enum Gradient {
        /// Header gradient — green theme
        static var header: LinearGradient {
            LinearGradient(
                colors: [.noBuyGreen, .noBuyGreen.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Card gradient — subtle tint
        static var card: LinearGradient {
            LinearGradient(
                colors: [
                    Color.noBuyGreen.opacity(0.08),
                    Color.noBuyGreen.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Button gradient — vibrant for CTAs
        static var button: LinearGradient {
            LinearGradient(
                colors: [.noBuyGreen, .noBuyGreen.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        /// Glow gradient — radial for backgrounds
        static var glow: RadialGradient {
            RadialGradient(
                colors: [
                    Color.noBuyGreen.opacity(0.20),
                    Color.noBuyGreen.opacity(0.05),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 200
            )
        }
    }

    // MARK: - Glass / Material Shortcuts

    enum Glass {
        /// Ultra thin material for overlays
        static let ultraThin = Material.ultraThinMaterial
        /// Regular material for cards
        static let regular = Material.regularMaterial
        /// Thick material for prominent surfaces
        static let thick = Material.thickMaterial
    }

    // MARK: - Shadow Presets

    enum Shadow {
        /// Subtle shadow for cards
        static let card = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )

        /// Medium shadow for buttons
        static let button = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 6,
            x: 0,
            y: 3
        )

        /// Prominent shadow for floating elements
        static let floating = ShadowStyle(
            color: Color.black.opacity(0.16),
            radius: 16,
            x: 0,
            y: 8
        )
    }
}

// MARK: - Shadow Style Helper

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    /// Apply a DS.Shadow preset
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
