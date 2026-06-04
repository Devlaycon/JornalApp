import SwiftUI

struct TipsView: View {

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 240/255, green: 249/255, blue: 255/255)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Communication Tips")
                                .font(.largeTitle.bold())

                            Text("Practice expressing yourself with confidence.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        tipCard(
                            title: "Speaking Up",
                            description: "Start with one sentence instead of waiting for the perfect moment."
                        )

                        tipCard(
                            title: "Active Listening",
                            description: "Focus on understanding before responding."
                        )

                        tipCard(
                            title: "Setting Boundaries",
                            description: "Being honest is not being rude."
                        )

                        VStack(spacing: 12) {

                            Image("penguin")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)

                            Text("Small steps build confidence.")
                                .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .padding()
                }
            }
        }
    }

    func tipCard(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            Text(title)
                .font(.headline)

            Text(description)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    TipsView()
}
