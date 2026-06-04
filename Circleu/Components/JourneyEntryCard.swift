import SwiftUI

struct JournalEntryCard: View {

    let title: String
    let mood: String
    let duration: String

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Text(title)
                    .fontWeight(.semibold)

                Spacer()

                Text(mood)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
            }

            HStack {

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Spacer()

                Text(duration)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
