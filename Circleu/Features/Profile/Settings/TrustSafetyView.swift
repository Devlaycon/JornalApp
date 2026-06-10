import SwiftUI

struct TrustSafetyView: View {
    var body: some View {
        List {

            Section("Trust & Safety") {

                NavigationLink("Privacy Policy") {
                    Text("Privacy Policy")
                        .padding()
                }

                NavigationLink("Community Guidelines") {
                    Text("Community Guidelines")
                        .padding()
                }

                NavigationLink("How Circleu Uses AI") {
                    Text("How Circleu Uses AI")
                        .padding()
                }

                NavigationLink("Safety & Wellbeing") {
                    Text("Safety & Wellbeing")
                        .padding()
                }
            }
        }
        .navigationTitle("Trust & Safety")
    }
}

#Preview {
    NavigationStack {
        TrustSafetyView()
    }
}
