//
//  SettingsView.swift
//  Kizba
//
//  Thin host for the Settings screen. MVP6 Phase B.3 split the
//  former monolithic scroll into a `TabView` (General / Security /
//  Git / Advanced) with a single shared `SettingsFooter` rendered
//  below the tabs. Tab content lives in `Tabs/*Tab.swift`; the
//  footer hosts the Save / Reset actions, the inline save-state
//  label, and the app version (the latter previously lived in a
//  `.safeAreaInset(.bottom)`).
//
//  The view keeps `model` ownership via `@State` (the model is a
//  `@MainActor @Observable` reference type) and forwards the same
//  instance to each tab and to the footer.
//

import SwiftUI

/// Settings screen bound to a `SettingsModel`.
public struct SettingsView: View {

    @State private var model: SettingsModel

    @Environment(\.theme) private var theme

    public init(model: SettingsModel) {
        _model = State(wrappedValue: model)
    }

    public var body: some View {
        VStack(spacing: 0) {
            TabView {
                GeneralTab(model: model)
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }

                SecurityTab(model: model)
                    .tabItem {
                        Label("Security", systemImage: "lock")
                    }

                GitTab(model: model)
                    .tabItem {
                        Label("Git", systemImage: "arrow.triangle.branch")
                    }

                AdvancedTab(model: model)
                    .tabItem {
                        Label("Advanced", systemImage: "slider.horizontal.3")
                    }
            }

            SettingsFooter(
                model: model,
                version: AppInfo.version,
                build: AppInfo.build
            )
        }
        .frame(minWidth: 520, minHeight: 420)
    }
}

// MARK: - Previews
#if DEBUG

struct SettingsView_Previews: PreviewProvider {
    /// Lightweight stub that always returns `nil` — no real binary lookup
    /// needed for SwiftUI previews.
    private struct PreviewDiscovery: BinaryLocating {
        func locate(_ binary: BinaryName) async -> URL? { nil }
        func reDetect() async {}
    }

    static var previews: some View {
        let env = AppEnvironment.preview()
        let model = SettingsModel(
            settings: env.settings,
            discovery: PreviewDiscovery(),
            recentStore: env.recentStore
        )
        SettingsView(model: model)
    }
}
#endif
