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
            EntryMenuCommands(state: state)
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

/// Top-level "Entry" menu. Phase C.5 introduced the menu with all
/// actions disabled; Phase F.3 enables "New Entry…" (⌘N) by
/// flipping `AppState.isNewEntrySheetPresented` — `EntryListView`
/// hosts the sheet via `.sheet(isPresented:)` and is therefore the
/// single rendering site regardless of which surface (toolbar,
/// menu, shortcut) triggered the present.
///
/// The remaining four items (Edit / Regenerate / Move / Delete)
/// stay disabled — they belong to Phase G.
///
/// `CommandMenu` (vs. `CommandGroup`) creates a brand-new top-level
/// menu after the system menus (typically between "View" and
/// "Window"), which is the documented placement for app-specific
/// verbs.
private struct EntryMenuCommands: Commands {

    /// Captured by `KizbaApp.body` so the menu can mutate the
    /// presentation flag from outside `EntryListView`. Marked
    /// `@Bindable` is unnecessary here — we never bind a property
    /// to a SwiftUI control inside the menu, only mutate the flag
    /// from a button action.
    let state: AppState

    var body: some Commands {
        CommandMenu("Entry") {
            Button("New Entry…") {
                state.isNewEntrySheetPresented = true
            }
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
