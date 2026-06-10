import SwiftUI

struct SettingsHubView: View {

    var body: some View {

        ScrollView {

            VStack(spacing: 16) {

                SettingsCard(
                    title: "Trust & Safety",
                    icon: "shield.fill",
                    destination: AnyView(
                        TrustSafetyView()
                    )
                )

                SettingsCard(
                    title: "Support",
                    icon: "questionmark.circle.fill",
                    destination: AnyView(
                        SupportView()
                    )
                )

                SettingsCard(
                    title: "About CircleU",
                    icon: "info.circle.fill",
                    destination: AnyView(
                        AboutView()
                    )
                )
            }
            .padding()
        }
        .navigationTitle("Information")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsCard: View {

    let title: String
    let icon: String
    let destination: AnyView

    var body: some View {

        NavigationLink {

            destination

        } label: {

            HStack(spacing: 16) {

                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.headline)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview{
    SettingsHubView()
}
