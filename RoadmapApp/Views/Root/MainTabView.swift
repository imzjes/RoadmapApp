import SwiftUI

struct MainTabView: View {
    @State private var selection: Tab = .today

    enum Tab: Hashable { case today, roadmap, review, settings }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { TodayView() }
                .tabItem { Label("Today", systemImage: "house") }
                .tag(Tab.today)

            NavigationStack { RoadmapView() }
                .tabItem { Label("Roadmap", systemImage: "map") }
                .tag(Tab.roadmap)

            NavigationStack { WeeklyReviewView() }
                .tabItem { Label("Review", systemImage: "chart.bar.xaxis") }
                .tag(Tab.review)

            NavigationStack { SettingsView() }
                .tabItem { Label("You", systemImage: "person.circle") }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
    }
}
