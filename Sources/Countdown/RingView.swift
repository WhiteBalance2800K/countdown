import SwiftUI

struct RingView<Content: View>: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 8
    var trackColor: Color = .black.opacity(0.10)
    @ViewBuilder let content: () -> Content

    var body: some View {
        let inset = lineWidth / 2

        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
                .padding(inset)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)
                .padding(inset)

            content()
        }
        .drawingGroup()
    }
}
