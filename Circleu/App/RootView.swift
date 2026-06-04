import SwiftUI

struct RootView: View {

    @State private var selectedTab: Tab = .home
    @State private var showRecording = false

    var body: some View {

        ZStack(alignment: .bottom) {

            switch selectedTab {

            case .home:
                HomeView()

            case .tips:
                TipsView()

            case .record:
                RecordEntryView()

            case .circle:
                CircleView()

            case .noot:
                ProfileView()
            }

            CustomTabBar(
                selectedTab: $selectedTab
            )
        }
    }
}
