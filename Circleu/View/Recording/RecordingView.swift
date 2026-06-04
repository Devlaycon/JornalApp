import SwiftUI
internal import Combine

struct RecordingView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var duration = 0
    @State private var navigateToReflection = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    Color(red: 0.84, green: 0.89, blue: 0.98),
                    Color(red: 0.94, green: 0.96, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {

                HStack {

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button {

                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
                .padding()

                Spacer()

                Text("Listening...")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("You can talk freely.")
                    .foregroundStyle(.white.opacity(0.8))

                WaveformView()
                    .padding(.vertical, 40)

                Image("penguin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)

                Text(timeString)
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .padding(.top)

                Spacer()

                HStack(spacing: 24) {

                    Button {

                    } label: {

                        Circle()
                            .fill(.white.opacity(0.8))
                            .frame(width: 70, height: 70)
                            .overlay {
                                Image(systemName: "pause.fill")
                                    .font(.title2)
                                    .foregroundStyle(.gray)
                            }
                    }

                    Button {
                        navigateToReflection = true
                    } label: {

                        Circle()
                            .fill(Color.blue)
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                    }
                }

                Text("Finish")
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                Spacer()
            }
        }
        .onReceive(timer) { _ in
            duration += 1
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToReflection) {
            ReflectionView()
        }
    }

    var timeString: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    RecordingView()
}
