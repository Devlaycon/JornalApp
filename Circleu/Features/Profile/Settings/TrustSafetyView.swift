import SwiftUI

struct TrustSafetyView: View {

    var body: some View {

        ScrollView {

            VStack(spacing: 16) {

                NavigationLink {
                    PolicyDetailView(
                        title: "Privacy Policy",
                        content: privacyPolicy
                    )
                } label: {
                    PolicyCard(
                        icon: "lock.shield.fill",
                        title: "Privacy Policy",
                        subtitle: "How your information is handled."
                    )
                }

                NavigationLink {
                    PolicyDetailView(
                        title: "Community Guidelines",
                        content: communityGuidelines
                    )
                } label: {
                    PolicyCard(
                        icon: "person.2.fill",
                        title: "Community Guidelines",
                        subtitle: "How we keep it safe and supportive."
                    )
                }

                NavigationLink {
                    PolicyDetailView(
                        title: "How CircleU Uses AI",
                        content: aiPolicy
                    )
                } label: {
                    PolicyCard(
                        icon: "sparkles",
                        title: "How CircleU Uses AI",
                        subtitle: "Understanding AI-generated insights."
                    )
                }

                NavigationLink {
                    PolicyDetailView(
                        title: "Safety & Wellbeing",
                        content: safetyPolicy
                    )
                } label: {
                    PolicyCard(
                        icon: "heart.fill",
                        title: "Safety & Wellbeing",
                        subtitle: "Supportive reflection, not therapy."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Trust & Safety")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicyCard: View {

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {

        HStack(spacing: 16) {

            Image(systemName: icon)
                .font(.title2)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
    }
}

#Preview{
    TrustSafetyView()
}
