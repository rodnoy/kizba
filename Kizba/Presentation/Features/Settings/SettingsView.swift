//
//  SettingsView.swift
//  Kizba
//
//  SwiftUI view for the Settings page. Binds to a
//  `SettingsModel` instance and exposes controls for path/binary
//  overrides, clipboard delay, and binary re-detection.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// Settings screen bound to a `SettingsModel`.
public struct SettingsView: View {

    @State private var model: SettingsModel
    @State private var showingResetConfirmation = false

    public init(model: SettingsModel) {
        _model = State(wrappedValue: model)
    }

    public var body: some View {
        Form {
            Section("General") {
                HStack {
                    TextField("Password store path override", text: bindingForOptional(&model.storePathOverride))
                        .textFieldStyle(.roundedBorder)
                    pickerButton(allowsDirectories: true) { url in
                        model.storePathOverride = url.path
                    }
                }
            }

            Section("Binaries") {
                HStack {
                    TextField("pass binary override", text: bindingForOptional(&model.passBinaryOverride))
                        .textFieldStyle(.roundedBorder)
                    pickerButton(allowsDirectories: false) { url in
                        model.passBinaryOverride = url.path
                    }
                }

                HStack {
                    TextField("gpg binary override", text: bindingForOptional(&model.gpgBinaryOverride))
                        .textFieldStyle(.roundedBorder)
                    pickerButton(allowsDirectories: false) { url in
                        model.gpgBinaryOverride = url.path
                    }
                }

                HStack {
                    TextField("pinentry binary override", text: bindingForOptional(&model.pinentryBinaryOverride))
                        .textFieldStyle(.roundedBorder)
                    pickerButton(allowsDirectories: false) { url in
                        model.pinentryBinaryOverride = url.path
                    }
                }

                HStack {
                    if model.isDetectingBinaries {
                        ProgressView()
                    }
                    Button("Re-detect binaries") {
                        Task { await model.reDetectBinaries() }
                    }
                    Spacer()
                }
            }

            Section("Clipboard") {
                HStack {
                    Stepper(value: $model.clipboardClearDelaySeconds, in: 5...300, step: 5) {
                        Text("Clipboard clear delay")
                    }
                    Spacer()
                    Text("\(model.clipboardClearDelaySeconds) s")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button("Save") {
                        model.save()
                    }
                    .keyboardShortcut(.defaultAction)

                    Button("Reset to Defaults") {
                        showingResetConfirmation = true
                    }
                    .keyboardShortcut(.cancelAction)
                    Spacer()
                }
            }
        }
        .padding()
        .frame(minWidth: 520)
        .alert("Reset to Defaults?", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive) {
                model.resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will clear all overrides and restore the clipboard delay to the default value.")
        }
    }

    // MARK: - Helpers

    /// Create a binding for an Optional<String> stored on the model. When
    /// the field is empty it will map to nil in the model.
    private func bindingForOptional(_ keyPath: WritableKeyPath<SettingsModel, String?>) -> Binding<String> {
        Binding<String>(
            get: { model[keyPath: keyPath] ?? "" },
            set: { newValue in
                model[keyPath: keyPath] = newValue.isEmpty ? nil : newValue
            }
        )
    }

    /// Platform-aware picker button. On macOS shows an `NSOpenPanel` and
    /// passes the selected URL to the handler. On other platforms the
    /// button is hidden (fallback to manual entry via TextField).
    @ViewBuilder
    private func pickerButton(allowsDirectories: Bool, completion: @escaping (URL) -> Void) -> some View {
#if canImport(AppKit)
        Button(action: {
            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.canChooseDirectories = allowsDirectories
            panel.allowsMultipleSelection = false
            panel.begin { response in
                guard response == .OK, let url = panel.url else { return }
                Task { @MainActor in completion(url) }
            }
        }) {
            Image(systemName: "ellipsis.circle")
        }
        .buttonStyle(.plain)
#else
        EmptyView()
#endif
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
        let model = SettingsModel(settings: env.settings, discovery: PreviewDiscovery())
        SettingsView(model: model)
    }
}
#endif
