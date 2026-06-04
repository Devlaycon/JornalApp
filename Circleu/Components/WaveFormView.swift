import SwiftUI

struct WaveFormView: View {

    @State private var animate = false

    private let heights: [CGFloat] = [
        20, 40, 28, 55, 32, 60,
        42, 65, 36, 58, 30, 48
    ]

    var body: some View {

        HStack(spacing: 8) {

            ForEach(0..<heights.count, id: \.self) { index in

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue)
                    .frame(
                        width: 6,
                        height: animate
                        ? heights[index]
                        : heights[index] * 0.4
                    )
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.05),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    WaveFormView()
}
