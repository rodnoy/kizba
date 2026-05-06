import SwiftUI

@main
struct KizbaApp: App {

    private let environment: AppEnvironment
    @State private var state: AppState

    init() {
        self.environment = AppEnvironment.live()
        self._state = State(initialValue: AppState())
    }

    var body: some Scene {
        WindowGroup {
            RootSplitView(environment: environment, state: state)
        }
    }
}
