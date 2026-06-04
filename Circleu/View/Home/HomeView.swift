import SwiftUI

struct HomeView: View {

    @State private var showRecording = false

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)

                    Text("LV4")
                        .fontWeight(.semibold)
                }
            }
            .padding()
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("Hey User,")
                    .font(.title3)
                Text("How was your day?")
                    .font(.largeTitle)
                    .bold()
            }
            Spacer()
            Circle()
                .fill(.gray.opacity(0.3))
                .frame(width: 180, height: 180)
                .overlay {
                    Text("NOOT")
                        .font(.headline)
                }
            Spacer()
            Button {
                showRecording = true
            } label: {
                Circle()
                    .fill(.red)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
            }
            Text("Tap to record")
                .foregroundColor(.gray)
            Spacer()
        }
        .fullScreenCover(isPresented: $showRecording) {
            RecordingView()
        }
    }
}

#Preview {
    HomeView()
}
