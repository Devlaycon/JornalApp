import SwiftUI

struct SupportView: View {
    var body: some View {
        List {

            NavigationLink("Help & FAQ") {
                Text("Help & FAQ")
                    .padding()
            }

            NavigationLink("Contact Us") {
                Text("circleu2026@gmail.com")
                    .padding()
            }

            NavigationLink("Send Feedback") {
                Text("We welcome your feedback.")
                    .padding()
            }
        }
        .navigationTitle("Support")
    }
}

#Preview {
    NavigationStack {
        SupportView()
    }
}
