import SwiftUI

struct WaveformView: View {

    let heights: [CGFloat] = [
        20, 45, 30, 70, 50,
        80, 40, 90, 60, 35,
        75, 45, 25
    ]

    var body: some View {

        HStack(alignment: .center, spacing: 6) {

            ForEach(heights.indices, id: \.self) { index in

                RoundedRectangle(cornerRadius: 10)
                    .fill(.blue)
                    .frame(
                        width: 8,
                        height: heights[index]
                    )
            }
        }
    }
}

#Preview {
    WaveformView()
}
