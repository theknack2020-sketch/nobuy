import SwiftUI
import UIKit

struct ScaleButtonStyle: ButtonStyle {
    let scale: CGFloat
    
    init(scale: CGFloat = 0.96) {
        self.scale = scale
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let isReduceMotion = UIAccessibility.isReduceMotionEnabled
        configuration.label
            .scaleEffect(isReduceMotion ? 1.0 : (configuration.isPressed ? scale : 1.0))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(isReduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scale: ScaleButtonStyle { ScaleButtonStyle() }
    static func scale(_ value: CGFloat) -> ScaleButtonStyle { ScaleButtonStyle(scale: value) }
}

// MARK: - Pressable Modifier for non-Button tappables

struct PressableModifier: ViewModifier {
    let scale: CGFloat
    @State private var isPressed = false

    init(scale: CGFloat = 0.96) {
        self.scale = scale
    }

    func body(content: Content) -> some View {
        let isReduceMotion = UIAccessibility.isReduceMotionEnabled
        content
            .scaleEffect(isReduceMotion ? 1.0 : (isPressed ? scale : 1.0))
            .opacity(isPressed ? 0.92 : 1.0)
            .animation(isReduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func pressable(scale: CGFloat = 0.96) -> some View {
        modifier(PressableModifier(scale: scale))
    }
}

// MARK: - Haptic Button Style (scale + haptic feedback)

struct HapticButtonStyle: ButtonStyle {
    let scale: CGFloat

    init(scale: CGFloat = 0.96) {
        self.scale = scale
    }

    func makeBody(configuration: Configuration) -> some View {
        let isReduceMotion = UIAccessibility.isReduceMotionEnabled
        configuration.label
            .scaleEffect(isReduceMotion ? 1.0 : (configuration.isPressed ? scale : 1.0))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(isReduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.tap()
                }
            }
    }
}

extension ButtonStyle where Self == HapticButtonStyle {
    static var hapticScale: HapticButtonStyle { HapticButtonStyle() }
    static func hapticScale(_ value: CGFloat) -> HapticButtonStyle { HapticButtonStyle(scale: value) }
}

// MARK: - Card Shadow Modifier

struct CardShadowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let y: CGFloat

    init(color: Color = .black.opacity(0.08), radius: CGFloat = 8, y: CGFloat = 4) {
        self.color = color
        self.radius = radius
        self.y = y
    }

    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius, x: 0, y: y)
    }
}

extension View {
    func cardShadow() -> some View {
        modifier(CardShadowModifier())
    }

    func ctaShadow() -> some View {
        modifier(CardShadowModifier(color: .noBuyGreen.opacity(0.3), radius: 12, y: 6))
    }
}
