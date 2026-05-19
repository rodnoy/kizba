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
///
/// Extra dependencies (`passManager`, `biometricAuth`, `settings`)
/// are accepted as `init` parameters but routed exclusively to the
/// MVP9.4 Data tab; the other tabs continue to consume the
/// ``SettingsModel`` they already had. When the new arguments are
/// omitted (test / preview wirings) the Data tab is elided so the
/// surface stays callable without changes.
public struct SettingsView: View {

    @State private var model: SettingsModel

    /// Optional — when nil, the Data tab is hidden. Preview / test
    /// wirings that don't supply a real ``PassManaging`` get a
    /// 4-tab Settings scene identical to the pre-MVP9.4 layout.
    private let dataTabDependencies: DataTabDependencies?

    @Environment(\.theme) private var theme

    /// Bundle of dependencies required by the Data tab. Kept as a
    /// nested type so test / preview wirings can opt out of the tab
    /// by passing `nil` instead of synthesising fake protocol values.
    public struct DataTabDependencies {
        public let passManager: any PassManaging
        public let biometricAuth: (any BiometricAuthenticating)?
        public let settings: any SettingsStoring

        public init(
            passManager: any PassManaging,
            biometricAuth: (any BiometricAuthenticating)?,
            settings: any SettingsStoring
        ) {
            self.passManager = passManager
            self.biometricAuth = biometricAuth
            self.settings = settings
        }
    }

    public init(
        model: SettingsModel,
        dataTabDependencies: DataTabDependencies? = nil
    ) {
        _model = State(wrappedValue: model)
        self.dataTabDependencies = dataTabDependencies
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

                if let deps = dataTabDependencies {
                    DataTab(
                        passManager: deps.passManager,
                        biometricAuth: deps.biometricAuth,
                        settings: deps.settings
                    )
                    .tabItem {
                        Label("Data", systemImage: "square.and.arrow.up.on.square")
                    }
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
