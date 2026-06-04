import SwiftUI

struct ReflectionView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Button("Save") {
                    dismiss()
                }
            }
            .padding(.horizontal)

            Text("Here's what I noticed")
                .font(.title)
                .bold()

            Circle()
                .fill(.gray.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay {
                    Text("🐧")
                        .font(.system(size: 40))
                }

            ReflectionCard(
                title: "♥︎ Emotion",
                content: "You seemed a little nervous sharing your thoughts today."
            )

            ReflectionCard(
                title: "★ Expression Moment",
                content: "You gave yourself space to express something honest."
            )

            ReflectionCard(
                title: "♣︎ Quote",
                content: "Confidence grows through expression, not perfection."
            )

            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ReflectionView()
}
