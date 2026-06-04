import SwiftUI

struct HomeView: View {

    @State private var showRecording = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(
                    red: 248 / 255,
                    green: 247 / 255,
                    blue: 243 / 255
                )
                .ignoresSafeArea()
                VStack {
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
                    Spacer()
                    VStack(alignment: .leading, spacing: 8) {

                        Text("Hey User,")
                            .font(.title3)

                        Text("How was your day?")
                            .font(.system(size: 36, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    Spacer()
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(.white)
                            Circle()
                                .stroke(
                                    Color.blue.opacity(0.15),
                                    lineWidth: 2
                                )
                            Image("penguin")
                                .resizable()
                                .scaledToFit()
                                .padding(20)
                        }
                        .frame(width: 220, height: 220)
                        VStack(spacing: 4) {
                            Text("Your voice is safe here.")
                                .font(.headline)
                            Text("Share your thoughts, feelings, or simply how your day went.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                    }
                    Spacer()
                    Button {
                        showRecording = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                            Image(systemName: "mic.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 90, height: 90)
                    }
                    Text("Tap to record")
                        .font(.headline)
                        .padding(.top, 12)
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showRecording) {
                RecordingView()
            }
        }
    }
}

#Preview {
    HomeView()
}
