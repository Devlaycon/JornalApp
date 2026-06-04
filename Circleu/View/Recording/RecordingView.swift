import SwiftUI

struct RecordingView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var showReflection = false
    @State private var recordingTime = 103

    var body: some View {

        ZStack {

            Color(red: 240/255, green: 249/255, blue: 255/255)
                .ignoresSafeArea()

            VStack {

                HStack {

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {

                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                Spacer()

                Text("Listening...")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.blue)

                Text("You can talk freely")
                    .foregroundStyle(.secondary)

                Spacer()

                WaveFormView()

                Spacer()

                VStack(spacing: 8) {

                    Text("RECORDING 1")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("June 1, 2024")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Image("penguin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90)

                Text(timeString)
                    .font(.system(size: 54, weight: .light))

                Spacer()

                HStack(spacing: 24) {

                    Button {

                    } label: {

                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 72, height: 72)
                            .overlay {
                                Image(systemName: "pause.fill")
                                    .font(.title2)
                                    .foregroundStyle(.gray)
                            }
                    }

                    Button {
                        showReflection = true
                    } label: {

                        Circle()
                            .fill(Color.blue)
                            .frame(width: 72, height: 72)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                    }
                }

                HStack(spacing: 52) {

                    Text("PAUSE")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("FINISH")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .fullScreenCover(
            isPresented: $showReflection
        ) {
            ReflectionView()
        }
    }

    var timeString: String {

        let minutes = recordingTime / 60
        let seconds = recordingTime % 60

        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
}

#Preview {
    RecordingView()
}
