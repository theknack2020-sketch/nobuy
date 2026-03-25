import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let colors: [Color] = [.noBuyGreen, .yellow, .orange, .blue, .pink, .purple]
    
    var body: some View {
        if reduceMotion {
            EmptyView()
        } else {
            ZStack {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: particle.isCircle ? particle.size / 2 : 2)
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.isCircle ? particle.size : particle.size * 0.5)
                        .shadow(color: particle.color.opacity(0.4), radius: 2, x: 0, y: 1)
                        .offset(x: particle.x, y: isAnimating ? particle.endY : particle.startY)
                        .rotationEffect(.degrees(isAnimating ? particle.rotation : 0))
                        .opacity(isAnimating ? 0 : 1)
                        .scaleEffect(isAnimating ? 0.3 : 1.0)
                }
            }
            .onAppear {
                generateParticles()
                withAnimation(.spring(response: 2.0, dampingFraction: 0.6)) {
                    isAnimating = true
                }
                HapticManager.celebration()
                SoundManager.playIfEnabled(.celebration)
            }
            .allowsHitTesting(false)
        }
    }
    
    private func generateParticles() {
        particles = (0..<50).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: -200...200),
                startY: CGFloat.random(in: -100...(-50)),
                endY: CGFloat.random(in: 300...600),
                size: CGFloat.random(in: 4...10),
                color: colors.randomElement()!,
                rotation: Double.random(in: 180...720),
                isCircle: Bool.random()
            )
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let color: Color
    let rotation: Double
    var isCircle: Bool = true
}
