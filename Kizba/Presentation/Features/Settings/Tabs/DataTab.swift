//
//  DataTab.swift
//  Kizba
//
//  Settings "Data" tab — Import / Export of the password store.
//
//  Dependencies are passed in directly (not via SettingsModel) so
//  the Settings scene's test surface stays unchanged. The tab
//  composes a `BiometricGate` inline on every export attempt to
//  honour any policy flips the user just made without saving.
//
//  Export gating: every export goes through `BiometricGate.run(...)`.
//  Import is intentionally NOT gated — it is a write operation, not
//  a raw secret read.
//
//  Known limitation: each `pass insert` performed during a batch
//  import produces its own git commit when the store is under git.
//  This is a `pass` CLI behaviour, not a Kizba bug; documented in
//  the Help topic added in MVP9.4e.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
import UniformTypeIdentifiers
#endif

struct DataTab: View {

    // MARK: - Injected dependencies

    let passManager: any PassManaging
    let biometricAuth: (any BiometricAuthenticating)?
    let settings: any SettingsStoring

    // MARK: - Local UI state

    @State private var importState: ImportFlowState = .idle
    @State private var exportState: ExportFlowState = .idle
    @State private var pendingPreview: IdentifiedImportPreview?

    @Environment(\.theme) private var theme

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.lg) {
                FormSection("Export") {
                    exportSection
                }
                FormSection("Import") {
                    importSection
                }
            }
            .padding(theme.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(item: $pendingPreview) { wrapper in
            ImportPreviewSheet(
                preview: wrapper.preview,
                onConfirm: { strategy in
                    let preview = wrapper.preview
                    pendingPreview = nil
                    Task { await executeImport(preview: preview, strategy: strategy) }
                },
                onCancel: {
                    pendingPreview = nil
                    importState = .idle
                }
            )
        }
    }

    // MARK: - Export

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            FormFieldRow(
                label: "Export store",
                infoText: "Exports every entry to an unencrypted file. Touch ID is required when the policy is enabled. The output file holds all passwords in plaintext — keep it private and delete it after use."
            ) {
                HStack(spacing: theme.spacing.sm) {
                    Menu {
                        Button("Bitwarden JSON…") {
                            Task { await beginExport(format: .bitwardenJSON) }
                        }
                        Button("Generic CSV…") {
                            Task { await beginExport(format: .genericCSV) }
                        }
                    } label: {
                        Label("Export…", systemImage: "square.and.arrow.up")
                    }
                    .disabled(exportState == .exporting)
                    .help("Export every entry to a file (Touch ID required)")

                    if exportState == .exporting {
                        ProgressView().controlSize(.small)
                    }
                    Spacer()
                }
            }

            if case .failed(let message) = exportState {
                Text("Export failed: \(message)")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.danger)
            }
            if case .completed(let count, let path) = exportState {
                Text("Exported \(count) entries to \(path).")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.success)
            }
        }
    }

    // MARK: - Import

    private var importSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            FormFieldRow(
                label: "Import entries",
                infoText: "Reads entries from a file and adds them to your store. Conflicts (paths already in the store) can be skipped, overwritten, or renamed with a numeric suffix."
            ) {
                HStack(spacing: theme.spacing.sm) {
                    Menu {
                        Button("Bitwarden JSON…") {
                            Task { await beginImport(format: .bitwardenJSON) }
                        }
                        Button("Generic CSV…") {
                            Task { await beginImport(format: .genericCSV) }
                        }
                        Button("1Password CSV…") {
                            Task { await beginImport(format: .onePasswordCSV) }
                        }
                    } label: {
                        Label("Import…", systemImage: "square.and.arrow.down")
                    }
                    .disabled(isImportBusy)
                    .help("Import entries from a Bitwarden, generic CSV, or 1Password CSV file")

                    if isImportBusy {
                        ProgressView().controlSize(.small)
                    }
                    Spacer()
                }
            }

            if case .importing(let progress, let done, let total) = importState {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    ProgressView(value: progress)
                    Text("Importing \(done) of \(total)…")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.onSurfaceMuted)
                }
            }
            if case .failed(let message) = importState {
                Text("Import failed: \(message)")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.danger)
            }
            if case .completed(let imported, let skipped, let failed) = importState {
                Text("Imported \(imported); skipped \(skipped); failed \(failed).")
                    .font(theme.typography.caption)
                    .foregroundStyle(failed > 0 ? theme.colors.warning : theme.colors.success)
            }
        }
    }

    private var isImportBusy: Bool {
        switch importState {
        case .parsing, .importing:
            return true
        case .idle, .completed, .failed:
            return pendingPreview != nil
        }
    }

    // MARK: - Biometric gate

    private var biometricGate: BiometricGate {
        BiometricGate(
            auth: biometricAuth,
            settings: settings,
            policyKey: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions)
        )
    }

    // MARK: - Export flow

    private func beginExport(format: ExportFormat) async {
        exportState = .exporting
        let allowed = await biometricGate.run(reason: "Export password store")
        guard allowed else {
            exportState = .idle
            return
        }

        do {
            let entries = try await passManager.listEntries()
            var records: [ExportRecord] = []
            records.reserveCapacity(entries.count)
            for entry in entries {
                let secret = try await passManager.show(entry)
                records.append(PassSecretExporter.toExportRecord(entry: entry, secret: secret))
            }

            let bytes: Data
            let defaultName: String
            let utType: UTType
            switch format {
            case .bitwardenJSON:
                bytes = try BitwardenJSONExporter().export(records: records)
                defaultName = "kizba-export.json"
                utType = .json
            case .genericCSV:
                let text = GenericCSVExporter().export(records: records)
                bytes = Data(text.utf8)
                defaultName = "kizba-export.csv"
                utType = .commaSeparatedText
            }

            guard let saveURL = await runSavePanel(defaultName: defaultName, utType: utType) else {
                exportState = .idle
                return
            }
            try bytes.write(to: saveURL, options: .atomic)
            exportState = .completed(count: records.count, path: saveURL.path)
        } catch {
            exportState = .failed(Self.shortMessage(for: error))
        }
    }

    // MARK: - Import flow

    private func beginImport(format: ImportFormat) async {
        importState = .parsing
        let utType: UTType
        switch format {
        case .bitwardenJSON: utType = .json
        case .genericCSV, .onePasswordCSV: utType = .commaSeparatedText
        }
        guard let pickedURL = await runOpenPanel(utType: utType) else {
            importState = .idle
            return
        }
        do {
            let data = try Data(contentsOf: pickedURL)
            let existingPaths = Set((try await passManager.listEntries()).map(\.path))

            let preview: ImportPreview
            switch format {
            case .bitwardenJSON:
                preview = try BitwardenJSONImporter().parse(data: data, existingPaths: existingPaths)
            case .genericCSV:
                let text = String(decoding: data, as: UTF8.self)
                preview = try GenericCSVImporter().parse(text: text, existingPaths: existingPaths)
            case .onePasswordCSV:
                let text = String(decoding: data, as: UTF8.self)
                preview = try OnePasswordCSVImporter().parse(text: text, existingPaths: existingPaths)
            }

            // Hand off to the sheet. `idle` keeps the inline status row
            // clean while the sheet is up.
            importState = .idle
            pendingPreview = IdentifiedImportPreview(preview)
        } catch {
            importState = .failed(Self.shortMessage(for: error))
        }
    }

    private func executeImport(preview: ImportPreview, strategy: ImportConflictStrategy) async {
        let resolver = ImportConflictResolver(
            strategy: strategy,
            existingPaths: Set(preview.records.map(\.path).filter { preview.conflicts.contains($0) })
        )

        let actions: [ImportConflictResolver.ResolvedAction] = preview.records.compactMap { resolver.resolve($0) }
        guard !actions.isEmpty else {
            importState = .completed(imported: 0, skipped: preview.conflictCount, failed: 0)
            return
        }

        var imported = 0
        var failed = 0
        let total = actions.count
        importState = .importing(progress: 0, done: 0, total: total)

        for (index, action) in actions.enumerated() {
            do {
                switch action {
                case .create(let record):
                    let entry = PassEntry(path: record.path)
                    let secret = Self.makePassSecret(from: record)
                    _ = try await passManager.insert(entry, secret: secret, force: false)
                case .overwrite(let record):
                    let entry = PassEntry(path: record.path)
                    let secret = Self.makePassSecret(from: record)
                    _ = try await passManager.insert(entry, secret: secret, force: true)
                }
                imported += 1
            } catch {
                // No rollback — collect the failure and continue.
                failed += 1
            }
            let done = index + 1
            importState = .importing(
                progress: Double(done) / Double(total),
                done: done,
                total: total
            )
        }

        let skipped = preview.records.count - actions.count
        importState = .completed(imported: imported, skipped: skipped, failed: failed)
    }

    // MARK: - Helpers

    private static func makePassSecret(from record: ExportRecord) -> PassSecret {
        var fields: [PassMetadata.Field] = []
        if let username = record.username, !username.isEmpty {
            fields.append(.init(key: "user", value: username))
        }
        if let url = record.url, !url.isEmpty {
            fields.append(.init(key: "url", value: url))
        }
        if let totp = record.totp, !totp.isEmpty {
            fields.append(.init(key: "otpauth", value: totp))
        }
        for (key, value) in record.extraFields.sorted(by: { $0.key < $1.key }) {
            fields.append(.init(key: key, value: value))
        }
        let metadata = PassMetadata(
            fields: fields,
            notes: record.notes
        )
        return PassSecret(password: record.password, metadata: metadata)
    }

    private static func shortMessage(for error: Error) -> String {
        if let pe = error as? PassError {
            return String(describing: pe)
        }
        if let importErr = error as? GenericCSVImporter.ImportError {
            switch importErr {
            case .emptyFile: return "The file is empty."
            case .missingNameColumn: return "Missing required column: name (or title)."
            case .missingPasswordColumn: return "Missing required column: password."
            }
        }
        return error.localizedDescription
    }

#if canImport(AppKit)
    /// Wraps `NSSavePanel.begin` in a continuation so it composes
    /// cleanly with the `async` flow. Returns `nil` when the user
    /// cancels.
    @MainActor
    private func runSavePanel(defaultName: String, utType: UTType) async -> URL? {
        await withCheckedContinuation { (cont: CheckedContinuation<URL?, Never>) in
            let panel = NSSavePanel()
            panel.allowedContentTypes = [utType]
            panel.nameFieldStringValue = defaultName
            panel.canCreateDirectories = true
            panel.title = "Export password store"
            panel.begin { response in
                cont.resume(returning: response == .OK ? panel.url : nil)
            }
        }
    }

    @MainActor
    private func runOpenPanel(utType: UTType) async -> URL? {
        await withCheckedContinuation { (cont: CheckedContinuation<URL?, Never>) in
            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            panel.allowedContentTypes = [utType]
            panel.title = "Import entries"
            panel.begin { response in
                cont.resume(returning: response == .OK ? panel.url : nil)
            }
        }
    }
#else
    @MainActor
    private func runSavePanel(defaultName: String, utType: Any) async -> URL? { nil }
    @MainActor
    private func runOpenPanel(utType: Any) async -> URL? { nil }
#endif
}

// MARK: - Flow state machines

enum ImportFlowState: Equatable {
    case idle
    case parsing
    case importing(progress: Double, done: Int, total: Int)
    case completed(imported: Int, skipped: Int, failed: Int)
    case failed(String)
}

enum ExportFlowState: Equatable {
    case idle
    case exporting
    case completed(count: Int, path: String)
    case failed(String)
}

enum ExportFormat {
    case bitwardenJSON
    case genericCSV
}

enum ImportFormat {
    case bitwardenJSON
    case genericCSV
    case onePasswordCSV
}
