import SwiftUI

/// A path field with optional folder-suggestions menu. When
/// `availableFolders` is empty, renders as a plain themed `TextField`.
/// Otherwise a trailing chevron button reveals a `Menu` of suggestions
/// that, when selected, replace `path`.
///
/// Phase F will wire real suggestion sources; this file ships only the
/// presentational shape.
public struct FolderPathPicker: View {
    @Binding private var path: String
    private let availableFolders: [String]
    private let placeholder: String

    public init(
        path: Binding<String>,
        availableFolders: [String] = [],
        placeholder: String = "folder/name"
    ) {
        self._path = path
        self.availableFolders = availableFolders
        self.placeholder = placeholder
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            TextField(text: $path, prompt: Text(placeholder)) {
                Text(placeholder)
            }
            .textFieldStyle(.kizba)
            .frame(maxWidth: .infinity)

            if !availableFolders.isEmpty {
                Menu {
                    ForEach(availableFolders, id: \.self) { folder in
                        Button(folder) {
                            path = folder
                        }
                    }
                } label: {
                    Image(systemName: "chevron.down")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .buttonStyle(.kizba(.ghost, size: .compact))
                .accessibilityLabel("Suggested folders")
            }
        }
    }
}
