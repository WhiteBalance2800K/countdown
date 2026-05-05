import SwiftUI

struct RingParticleEffect: View {
    let color: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let baseRadius = min(size.width, size.height) * 0.39

                for index in 0..<12 {
                    let phase = Double(index) / 12.0
                    let speed = 0.72 + Double(index % 4) * 0.08
                    let angle = time * speed + phase * .pi * 2
                    let pulse = (sin(time * 2.2 + Double(index)) + 1) / 2
                    let radius = baseRadius + CGFloat(pulse) * 3.2
                    let diameter = CGFloat(1.25 + pulse * 1.15)
                    let opacity = 0.16 + pulse * 0.42
                    let point = CGPoint(
                        x: center.x + cos(angle) * radius,
                        y: center.y + sin(angle) * radius
                    )
                    let rect = CGRect(
                        x: point.x - diameter / 2,
                        y: point.y - diameter / 2,
                        width: diameter,
                        height: diameter
                    )

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(color.opacity(opacity))
                    )
                }
            }
        }
        .blur(radius: 0.15)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
