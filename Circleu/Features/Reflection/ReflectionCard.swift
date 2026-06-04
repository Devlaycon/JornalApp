import SwiftUI

struct ReflectionCard: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            Text(content)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    ReflectionCard(
        title: "Emotion",
        content: "You seemed a little nervous sharing your thoughts today."
    )
    .padding()
}
