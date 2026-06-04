import SwiftUI

struct HomeView: View {

    @State private var showRecording = false

    var body: some View {

        ZStack {

            Color(red: 240/255, green: 249/255, blue: 255/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                HStack {

                    Button {

                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundStyle(.black)
                    }

                    Spacer()

                    HStack(spacing: 4) {

                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)

                        Text("12")
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                VStack(alignment: .leading, spacing: 6) {

                    Text("Hey there 👋")
                        .font(.title3)

                    Text("How was your day?")
                        .font(.system(size: 34, weight: .bold))

                    Text("Take a moment to share your thoughts.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                Spacer()

                ZStack {

                    Circle()
                        .fill(.white)

                    Circle()
                        .stroke(
                            Color.blue.opacity(0.12),
                            lineWidth: 2
                        )

                    Image("penguin")
                        .resizable()
                        .scaledToFit()
                        .padding(20)

                    VStack {

                        HStack {

                            Spacer()

                            Image(systemName: "heart.fill")
                                .foregroundStyle(.blue)
                                .padding(10)
                                .background(.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }

                        Spacer()
                    }
                    .padding(18)
                }
                .frame(width: 230, height: 230)

                VStack(spacing: 8) {

                    Text("Your voice is safe here")
                        .font(.headline)

                    Text("Share your thoughts, feelings, or simply how your day went.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 24)

                Spacer()

                Button {
                    showRecording = true
                } label: {

                    ZStack {

                        Circle()
                            .fill(Color(red: 37/255, green: 99/255, blue: 235/255))

                        Circle()
                            .stroke(
                                Color.blue.opacity(0.15),
                                lineWidth: 16
                            )

                        Image(systemName: "mic.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 100, height: 100)
                }

                Text("Tap to record")
                    .font(.headline)
                    .padding(.top, 14)

                Spacer()
            }
        }
        .fullScreenCover(
            isPresented: $showRecording
        ) {
            RecordingView()
        }
    }
}

#Preview {
    HomeView()
}
