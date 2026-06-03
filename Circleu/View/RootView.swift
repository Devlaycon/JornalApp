import SwiftUI

struct RootView: View {

    var body: some View {

        TabView {

            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            JournalView()
                .tabItem {
                    Image(systemName: "mic.fill")
                    Text("Journal")
                }

            CircleView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Circle")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Noot")
                }
        }
        .tint(Color.blue)
    }
}

#Preview {
    RootView()
}
