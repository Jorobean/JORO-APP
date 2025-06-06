import SwiftUI

struct ConfettiView: View {
    @Binding var trigger: Bool
    let colors: [Color] = [.red, .green, .blue, .orange, .yellow, .purple]
    let confettiCount = 24

    var body: some View {
        ZStack {
            ForEach(0..<confettiCount, id: \. self) { i in
                ConfettiParticle(trigger: $trigger, color: colors[i % colors.count], index: i)
            }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiParticle: View {
    @Binding var trigger: Bool
    let color: Color
    let index: Int
    @State private var yOffset: CGFloat = -100
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .offset(x: xOffset, y: yOffset)
            .rotationEffect(.degrees(rotation))
            .opacity(trigger ? 1 : 0)
            .onChange(of: trigger) { newValue in
                if newValue {
                    withAnimation(.interpolatingSpring(stiffness: 80, damping: 8).delay(Double(index) * 0.02)) {
                        yOffset = CGFloat.random(in: 120...260)
                        xOffset = CGFloat.random(in: -140...140)
                        rotation = Double.random(in: 0...360)
                    }
                    // Reset after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        yOffset = -100
                        xOffset = 0
                        rotation = 0
                    }
                }
            }
    }
}
