import SwiftUI

struct ReflectionCard: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(PinguDesign.ink)

            Text(content)
                .font(.subheadline)
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .pinguGlass(cornerRadius: 24, tint: 0.22)
    }
}

#Preview {
    ReflectionCard(
        title: "Emotion",
        content: "You seemed a little nervous sharing your thoughts today."
    )
    .padding()
}
