import ComposableArchitecture
import SwiftUI

@main
struct SnapApp: App {
    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
                .onChange(of: scenePhase) { _, newPhase in
                    store.send(.scenePhaseChanged(newPhase))
                }
        }
    }
}
