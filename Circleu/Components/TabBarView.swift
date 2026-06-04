import SwiftUI

struct CustomTabBar: View {

    @Binding var selectedTab: Tab

    var body: some View {

        HStack {

            tabButton(
                image: "house",
                title: "Home",
                tab: .home
            )

            Spacer()

            tabButton(
                image: "sparkles",
                title: "Tips",
                tab: .tips
            )

            Spacer()

            tabButton(
                image: "person.3",
                title: "Circle",
                tab: .circle
            )

            Spacer()

            tabButton(
                image: "person",
                title: "Noot",
                tab: .noot
            )
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.08), radius: 12)
        .padding(.horizontal)
    }

    func tabButton(
        image: String,
        title: String,
        tab: Tab
    ) -> some View {

        Button {

            selectedTab = tab

        } label: {

            VStack(spacing: 6) {

                Image(systemName: image)
                    .font(.system(size: 18))

                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(
                selectedTab == tab
                ? Color.blue
                : Color.gray
            )
        }
    }
}
