import SwiftUI

struct SettingsHubView: View {
    var body: some View {
        List {
            NavigationLink("Trust & Safety") {
                TrustSafetyView()
            }

            NavigationLink("Support") {
                SupportView()
            }

            NavigationLink("About Circleu") {
                AboutView()
            }
        }
        .navigationTitle("About Circleu")
    }
}

#Preview {
    NavigationStack {
        SettingsHubView()
    }
}
