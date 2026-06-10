import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {

            VStack(alignment: .leading, spacing: 16) {

                Text("About Circleu")
                    .font(.title2.bold())

                Text("""
Circleu is a reflection companion designed to help people build social confidence through reflection, growth, and connection.
""")

                Divider()

                Text("Version 1.0.0")
                    .font(.headline)

                Text("""
Developed as part of the Apple Foundation Program

University of Technology Sydney

2026
""")
            }
            .padding()
        }
        .navigationTitle("About")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
