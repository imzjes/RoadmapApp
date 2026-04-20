import SwiftData
import SwiftUI

@main
struct RoadmapAppApp: App {
    @State private var flow = FlowModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(flow)
        }
        .modelContainer(RoadmapStore.shared.container)
    }
}
