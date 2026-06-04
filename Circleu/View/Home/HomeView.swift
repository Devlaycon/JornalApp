import SwiftUI

struct HomeView: View {

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    Color(
                        red: 248/255,
                        green: 251/255,
                        blue: 255/255
                    ),
                    .white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    HStack {

                        Image(systemName: "line.3.horizontal")
                            .font(.title3)

                        Spacer()

                        HStack(spacing: 4) {

                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)

                            Text("12")
                                .fontWeight(.semibold)
                        }
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text("Hey there 👋")
                            .font(.title3)

                        Text("How was your day?")
                            .font(
                                .system(
                                    size: 36,
                                    weight: .bold
                                )
                            )

                        Text("Take a moment to share your thoughts.")
                            .foregroundStyle(.secondary)
                    }

                    HStack {

                        Spacer()

                        ZStack {

                            Circle()
                                .fill(.white)

                            Circle()
                                .stroke(
                                    Color.blue.opacity(0.1),
                                    lineWidth: 2
                                )

                            Image("penguin")
                                .resizable()
                                .scaledToFit()
                                .padding(30)
                        }
                        .frame(
                            width: 200,
                            height: 200
                        )

                        Spacer()
                    }

                    dashboardCard(
                        title: "Today's Prompt",
                        subtitle: "What made you smile today?",
                        icon: "sparkles"
                    )

                    dashboardCard(
                        title: "12 Day Streak",
                        subtitle: "Keep sharing your thoughts.",
                        icon: "flame.fill"
                    )

                    dashboardCard(
                        title: "Community Highlight",
                        subtitle: "Someone shared their first class presentation experience.",
                        icon: "person.3.fill"
                    )

                    dashboardCard(
                        title: "Recent Reflection",
                        subtitle: "You spoke honestly about your experience.",
                        icon: "heart.fill"
                    )

                    Color.clear
                        .frame(height: 120)
                }
                .padding()
            }
        }
    }

    func dashboardCard(
        title: String,
        subtitle: String,
        icon: String
    ) -> some View {

        HStack(spacing: 16) {

            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(title)
                    .fontWeight(.semibold)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.white)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
        .shadow(
            color: .black.opacity(0.04),
            radius: 8
        )
    }
}

#Preview {
    HomeView()
}
