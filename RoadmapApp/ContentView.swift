import SwiftUI

/// Legacy entry from the Xcode template. Kept as a preview host; real
/// navigation is driven by `RootView` via `FlowModel`.
struct ContentView: View {
    var body: some View {
        RootView()
            .environment(FlowModel())
    }
}

#Preview {
    ContentView()
}
