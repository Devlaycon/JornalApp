import SwiftUI

struct RecordingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showReflection = false

    var body: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.black)
                }

                Spacer()
            }
            .padding()

            Spacer()

            Text("Listening...")
                .font(.largeTitle)
                .bold()

            Text("Talk freely, there's no right answer.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Spacer()

            Circle()
                .fill(.gray.opacity(0.2))
                .frame(width: 120, height: 120)
                .overlay {
                    Text("🐧")
                        .font(.system(size: 50))
                }

            Spacer()

            WaveformView()

            Spacer()

            Text("00:18")
                .font(.system(size: 42, weight: .bold))
                .monospacedDigit()

            Spacer()

            HStack(spacing: 16) {
                Button {

                } label: {
                    HStack {
                        Image(systemName: "pause.fill")
                        Text("Pause")
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.gray.opacity(0.15))
                    .cornerRadius(20)
                }

                Button {
                    showReflection = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Finish")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .fullScreenCover(isPresented: $showReflection) {
            ReflectionView()
        }
    }
}

#Preview {
    RecordingView()
}
