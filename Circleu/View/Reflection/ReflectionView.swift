import SwiftUI

struct ReflectionView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        ZStack {

            Color(
                red: 248 / 255,
                green: 247 / 255,
                blue: 243 / 255
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {

                HStack {

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }

                    Spacer()

                    Text("Reflection")
                        .fontWeight(.semibold)

                    Spacer()

                    Image(systemName: "square.and.arrow.up")
                }
                .padding()

                Image("penguin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90)

                Text("Here's what I noticed")
                    .font(.title2)
                    .fontWeight(.bold)

                ReflectionCard(
                    icon: "heart.fill",
                    title: "Emotion",
                    content: "You seemed nervous about being judged. That's completely normal."
                )

                ReflectionCard(
                    icon: "sparkles",
                    title: "Expression Moment",
                    content: "You spoke honestly about your experience. That took courage."
                )

                VStack(alignment: .leading, spacing: 12) {

                    Text("QUOTE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Confidence grows through expression.")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Spacer()

                HStack {

                    Button("Cancel") {

                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button("Save Entry") {

                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Text("Saved entries are private to you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ReflectionView()
}
