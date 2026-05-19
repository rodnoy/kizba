import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

@main
struct KizbaApp: App {

    private let environment: AppEnvironment
    private let searchModel: SearchModel
    @State private var state: AppState
    #if canImport(AppKit)
    private let statusItemController: StatusItemController?
    private let userDefaultsObserver: NSObjectProtocol?
    #else
    private let statusItemController: StatusItemController? = nil
    private let userDefaultsObserver: NSObjectProtocol? = nil
    #endif

    init() {
        let env = AppEnvironment.live()
        self.environment = env
        self.searchModel = SearchModel(searchEngine: LiveSearchEngine(passManager: env.passManager))
        // Phase G.1: `AppState` constructs an `ActionHistory` and
        // therefore needs the real `PassManaging` so undo invokes the
        // production CLI rather than a debug double.
        self._state = State(initialValue: AppState(passManager: env.passManager))

        #if canImport(AppKit)
        let menuBarModel = MenuBarModel(
            searchEngine: env.searchEngine,
            recentStore: env.recentStore,
            favoritesStore: env.favoritesStore,
            clipboard: env.clipboard,
            passManager: env.passManager,
            settings: env.settings,
            biometricAuth: env.biometricAuth
        )
        let statusItemController = StatusItemController(
            environment: env,
            content: { AnyView(MenuBarPopoverView(model: menuBarModel)) }
        )

        let show = env.settings.value(for: SettingsKey<Bool>(SettingsKeys.showInMenuBar))
            ?? SettingsKeys.defaultShowInMenuBar
        if show {
            Task { @MainActor in
                statusItemController.show()
            }
        }

        let observer = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            let shouldShow = env.settings.value(for: SettingsKey<Bool>(SettingsKeys.showInMenuBar))
                ?? SettingsKeys.defaultShowInMenuBar
            Task { @MainActor in
                if shouldShow {
                    statusItemController.show()
                } else {
                    statusItemController.hide()
                }
            }
        }

        self.statusItemController = statusItemController
        self.userDefaultsObserver = observer
        #endif
    }

    var body: some Scene {
        // Each top-level Scene gets its own `ThemedRoot` because separate
        // scene trees do not share `@Environment` state — theme injection
        // must happen at every scene root independently (Phase B.2).
        WindowGroup {
            ThemedRoot {
                RootSplitView(environment: environment, searchModel: searchModel, state: state)
                    .task {
                        await environment.wireGitModelIfAvailable(into: state)
                    }
                    .sheet(
                        isPresented: Binding(
                            get: { state.router.isGitConflictBannerPresented },
                            set: { state.router.isGitConflictBannerPresented = $0 }
                        )
                    ) {
                        if let gitModel = state.gitStatusModel {
                            GitConflictBanner(
                                model: gitModel,
                                storePath: environment.storeURL.path,
                                // MVP4 fix-pack v1, Fix 4 — was
                                // `NSWorkspace.shared.open(URL)`
                                // for a directory URL, which opens
                                // Finder, not Terminal. Delegate to
                                // the model's single source of
                                // truth (`open -a Terminal <path>`).
                                openTerminalAction: { gitModel.openTerminalAtStore() }
                            )
                        }
                    }
            }
        }
            .commands {
            DiagnosticsCommands()
            HelpCommands()
            EntryMenuCommands(state: state, favoritesStore: environment.favoritesStore)
            if state.gitStatusModel != nil {
                // MVP4 fix-pack v1, Fix 4 — pass `onOpenTerminal`
                // so the "Open Terminal at Store" menu item is no
                // longer a silent no-op.
                GitMenuCommands(
                    state: state,
                    onOpenTerminal: { state.gitStatusModel?.openTerminalAtStore() }
                )
            }
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
                        discovery: environment.discovery!,
                        recentStore: environment.recentStore,
                        biometricAuth: environment.biometricAuth
                    ),
                    dataTabDependencies: SettingsView.DataTabDependencies(
                        passManager: environment.passManager,
                        biometricAuth: environment.biometricAuth,
                        settings: environment.settings
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
        // Dedicated Help window, opened via `Help > Kizba Help…` (⌘⇧?)
        // declared in `HelpCommands`. Reuses the SHARED clipboard
        // instance from `environment.clipboard` so any future
        // telemetry on copy events flows through the same actor as
        // secret copies.
        Window("Help", id: "help") {
            ThemedRoot {
                HelpView(
                    model: HelpModel(clipboard: environment.clipboard)
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

/// Adds a `Help > Kizba Help…` menu item bound to ⌘⇧? that opens
/// the dedicated Help scene. Replaces the system-default Help item
/// (which on macOS opens an HTML help bundle Kizba does not ship)
/// while preserving the localised "Help" menu name. Lives in its
/// own `Commands` value because `openWindow` must be read from the
/// SwiftUI environment.
///
/// Visibility is `internal` (rather than the `private` used by
/// `DiagnosticsCommands`) so `KizbaTests/HelpCommandCardTests` can
/// assert `helpWindowID` without reflection.
struct HelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    /// Stable identifier for the Help scene. Exposed as a `static`
    /// constant so `KizbaTests/HelpCommandCardTests` can assert
    /// the value without reaching into the SwiftUI body.
    static let helpWindowID: String = "help"

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("Kizba Help…") {
                openWindow(id: HelpCommands.helpWindowID)
            }
            .keyboardShortcut("?", modifiers: [.command, .shift])
        }
    }
}

/// Top-level "Entry" menu. Phase C.5 introduced the menu with all
/// actions disabled; Phase F.3 enables "New Entry…" (⌘N), Phase
/// G.2 enables "Edit Entry…" (⌘E), Phase G.3 enables
/// "Regenerate Password" (⌘⌥G), Phase G.4 enables
/// "Move Entry…" (⌘⇧M), and Phase G.5 enables "Delete Entry"
/// (⌫) — each one flips its corresponding
/// `AppState.is*Sheet/ConfirmationPresented` flag and the matching
/// view hosts the sheet / dialog at a single rendering site
/// regardless of which surface (toolbar, menu, shortcut) triggered
/// the present.
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
    let favoritesStore: any FavoritesStoring

    var body: some Commands {
        CommandMenu("Entry") {
            Button("Search…") {
                state.router.isSearchSheetPresented = true
            }
            .keyboardShortcut("k", modifiers: .command)

            // Phase G.6 — every write-side menu item is also gated
            // on `state.anyWriteInFlight`. The lockout matches the
            // toolbar buttons: while ANY write op is running, all
            // five write affordances disable so the user cannot
            // trigger a concurrent write.
            Button("New Entry…") {
                state.router.isNewEntrySheetPresented = true
            }
            .disabled(state.anyWriteInFlight)
            .keyboardShortcut("n", modifiers: .command)

            Button("Edit Entry…") {
                state.router.isEditEntrySheetPresented = true
            }
            .disabled(state.router.selectedEntryID == nil || state.anyWriteInFlight)
            .keyboardShortcut("e", modifiers: .command)

            Button("Regenerate Password") {
                state.router.isRegenerateInPlaceSheetPresented = true
            }
            .disabled(state.router.selectedEntryID == nil || state.anyWriteInFlight)
            .keyboardShortcut("g", modifiers: [.command, .option])

            Button("Move Entry…") {
                state.router.isMoveEntrySheetPresented = true
            }
            .disabled(state.router.selectedEntryID == nil || state.anyWriteInFlight)
            .keyboardShortcut("m", modifiers: [.command, .shift])

            Button("Toggle Favorite") {
                guard let id = state.router.selectedEntryID else { return }
                Task { await favoritesStore.toggleFavorite(id) }
            }
            .disabled(state.router.selectedEntryID == nil)
            .keyboardShortcut("d", modifiers: .command)

            // Phase G.5 — flip the shared
            // `isDeleteConfirmationPresented` flag; the actual
            // destructive `confirmationDialog` is hosted by
            // `EntryListView` via the C.1
            // `destructiveConfirmation` modifier. Disabled without
            // a selection so ⌫ is a no-op when the entry list has
            // no active row.
            Button("Delete Entry") {
                state.router.isDeleteConfirmationPresented = true
            }
            .disabled(state.router.selectedEntryID == nil || state.anyWriteInFlight)
            .keyboardShortcut(.delete, modifiers: [])
        }
    }
}
