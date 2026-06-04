import SwiftUI

struct ReflectionCard: View {

    let icon: String
    let title: String
    let content: String

    var body: some View {

        HStack(alignment: .top, spacing: 12) {

            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 6) {

                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Text(content)
                    .font(.body)
            }

            Spacer()
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
