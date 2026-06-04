import SwiftUI

struct ProfileView: View {

    var body: some View {

        NavigationStack {

            ZStack {

                Color(red: 240/255, green: 249/255, blue: 255/255)
                    .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 20) {

                        VStack(spacing: 16) {

                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 100, height: 100)
                                .overlay {
                                    Image("penguin")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(15)
                                }

                            Text("Pingu")
                                .font(.title2.bold())

                            Text("Confident Explorer")
                                .foregroundStyle(.secondary)
                        }

                        progressCard

                        menuCard(title: "Journal History", icon: "book")
                        menuCard(title: "My Circles", icon: "person.3")
                        menuCard(title: "Settings", icon: "gear")
                    }
                    .padding()
                }
            }
        }
    }

    var progressCard: some View {

        VStack(spacing: 16) {

            Text("Level 4")

            ProgressView(value: 0.7)

            HStack {

                stat(title: "Entries", value: "23")

                Spacer()

                stat(title: "Streak", value: "12")

                Spacer()

                stat(title: "Growth", value: "80%")
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    func stat(title: String, value: String) -> some View {

        VStack {
            Text(value)
                .font(.title3.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    func menuCard(title: String, icon: String) -> some View {

        HStack {

            Image(systemName: icon)

            Text(title)

            Spacer()

            Image(systemName: "chevron.right")
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ProfileView()
}
