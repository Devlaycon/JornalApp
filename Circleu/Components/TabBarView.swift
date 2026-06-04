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

            recordButton

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
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 26
            )
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 12,
            y: 4
        )
        .padding(.horizontal)
        .padding(.bottom, 10)
    }

    var recordButton: some View {

        Button {

            selectedTab = .record

        } label: {

            ZStack {

                Capsule()
                    .fill(
                        Color(
                            red: 37/255,
                            green: 99/255,
                            blue: 235/255
                        )
                    )
                    .frame(
                        width: 74,
                        height: 40
                    )

                Image(systemName: "mic.fill")
                    .foregroundStyle(.white)
            }
        }
    }

    func tabButton(
        image: String,
        title: String,
        tab: Tab
    ) -> some View {

        Button {

            selectedTab = tab

        } label: {

            VStack(spacing: 4) {

                Image(systemName: image)
                    .font(.system(size: 18))

                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(
                selectedTab == tab
                ? Color(
                    red: 37/255,
                    green: 99/255,
                    blue: 235/255
                )
                : Color.gray
            )
        }
    }
}
