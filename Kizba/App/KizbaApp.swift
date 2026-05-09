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
        // Each top-level Scene gets its own `ThemedRoot` because separate
        // scene trees do not share `@Environment` state — theme injection
        // must happen at every scene root independently (Phase B.2).
        WindowGroup {
            ThemedRoot {
                RootSplitView(environment: environment, state: state)
            }
        }
        .commands {
            DiagnosticsCommands()
            EntryMenuCommands()
        }
        // Standard macOS Settings scene. Reuses the SHARED
        // `BinaryDiscoveryService` from `AppEnvironment.live()` so that
        // "Re-detect binaries" invalidates the very same cache used by
        // `LivePassCLI` (Phase A.4). `discovery` is non-nil by design
        // in the live wiring; preview/test wirings do not run the
        // Settings scene.
        Settings {
            ThemedRoot {
                SettingsView(
                    model: SettingsModel(
                        settings: environment.settings,
                        discovery: environment.discovery!
                    )
                )
            }
        }
        // Dedicated Diagnostics window (macOS 13+), opened via the
        // `Window > Diagnostics…` menu item (⌘⌥D) declared in
        // `DiagnosticsCommands`. The hosted `DiagnosticsModel` MUST
        // wrap the SHARED `InvocationLog` carried by `environment` so
        // the window renders the same recorded invocations published
        // by `ProcessShellRunner`. In live wiring `invocationLog` is
        // always populated; preview/test wirings do not run this
        // scene.
        Window("Diagnostics", id: "diagnostics") {
            ThemedRoot {
                DiagnosticsView(
                    model: DiagnosticsModel(
                        invocationLog: environment.invocationLog!
                    )
                )
            }
        }
    }
}

// MARK: - Commands

/// Adds a `Window > Diagnostics…` menu item bound to ⌘⌥D that opens
/// the dedicated Diagnostics scene. Lives in its own `Commands` value
/// because `openWindow` must be read from the SwiftUI environment,
/// which requires a `Commands`-conforming type with an `@Environment`
/// property.
private struct DiagnosticsCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .windowList) {
            Button("Diagnostics…") {
                openWindow(id: "diagnostics")
            }
            .keyboardShortcut("d", modifiers: [.command, .option])
        }
    }
}

/// Top-level "Entry" menu placeholder shipped in Phase C.5. The actions
/// here are intentionally **disabled** — the underlying write features
/// (create / edit / regenerate / move / delete) land in Phases F and G.
/// Declaring the menu and its keyboard shortcuts now keeps the
/// shortcut surface stable for users and lets the wiring in F/G
/// flip `.disabled` to a real `@FocusedValue`-driven binding without
/// reshuffling the menu structure.
///
/// `CommandMenu` (vs. `CommandGroup`) creates a brand-new top-level
/// menu after the system menus (typically between "View" and
/// "Window"), which is the documented placement for app-specific
/// verbs.
private struct EntryMenuCommands: Commands {
    var body: some Commands {
        CommandMenu("Entry") {
            Button("New Entry…") {
                // TODO: Phase F — present `NewEntrySheet`.
            }
            .disabled(true)
            .keyboardShortcut("n", modifiers: .command)

            Button("Edit Entry…") {
                // TODO: Phase G — present `EditEntrySheet` for selection.
            }
            .disabled(true)
            .keyboardShortcut("e", modifiers: .command)

            Button("Regenerate Password") {
                // TODO: Phase G — present `InPlaceGenerateSheet` for selection.
            }
            .disabled(true)
            .keyboardShortcut("g", modifiers: [.command, .option])

            Button("Move Entry…") {
                // TODO: Phase G — present `MoveEntrySheet` for selection.
            }
            .disabled(true)
            .keyboardShortcut("m", modifiers: [.command, .shift])

            Button("Delete Entry") {
                // TODO: Phase G — two-step destructive confirmation + Undo.
            }
            .disabled(true)
            .keyboardShortcut(.delete, modifiers: [])
        }
    }
}
