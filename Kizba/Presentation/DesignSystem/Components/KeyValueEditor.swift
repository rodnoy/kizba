import SwiftUI

/// UI for editing an ordered list of `(key, value)` pairs. Used by the
/// metadata editor in Phase F/G; here only the presentational shell is
/// shipped — actual validation lives in `EntryFormModel` later. Inputs
/// are not gated.
public struct KeyValueEditor: View {
    public struct Pair: Identifiable, Sendable, Equatable {
        public let id: UUID
        public var key: String
        public var value: String

        public init(id: UUID = UUID(), key: String, value: String) {
            self.id = id
            self.key = key
            self.value = value
        }
    }

    @Binding private var pairs: [Pair]
    private let keyPlaceholder: String
    private let valuePlaceholder: String
    private let addButtonLabel: String

    public init(
        pairs: Binding<[Pair]>,
        keyPlaceholder: String = "key",
        valuePlaceholder: String = "value",
        addButtonLabel: String = "Add field"
    ) {
        self._pairs = pairs
        self.keyPlaceholder = keyPlaceholder
        self.valuePlaceholder = valuePlaceholder
        self.addButtonLabel = addButtonLabel
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            ForEach(Array(pairs.enumerated()), id: \.element.id) { index, pair in
                row(for: pair, index: index)
            }

            Button {
                pairs.append(Pair(key: "", value: ""))
            } label: {
                Label(addButtonLabel, systemImage: "plus.circle")
            }
            .buttonStyle(.kizba(.secondary, size: .compact))
        }
    }

    private func row(for pair: Pair, index: Int) -> some View {
        HStack(spacing: theme.spacing.sm) {
            TextField(keyPlaceholder, text: binding(for: pair, keyPath: \.key))
                .textFieldStyle(.kizba)
                .frame(maxWidth: .infinity)

            TextField(valuePlaceholder, text: binding(for: pair, keyPath: \.value))
                .textFieldStyle(.kizba)
                .frame(maxWidth: .infinity)

            Button {
                pairs.removeAll { $0.id == pair.id }
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.kizba(.ghost, size: .compact))
            .accessibilityLabel("Remove field")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(KeyValueEditor.rowAccessibilityLabel(index: index))
    }

    // MARK: - Pure helpers

    static func rowAccessibilityLabel(index: Int) -> String {
        "Field row \(index + 1)"
    }

    /// Two-way binding into a single field of a single pair, scoped by
    /// `id` so reordering / removal stays consistent.
    private func binding(for pair: Pair, keyPath: WritableKeyPath<Pair, String>) -> Binding<String> {
        Binding(
            get: {
                guard let index = pairs.firstIndex(where: { $0.id == pair.id }) else {
                    return pair[keyPath: keyPath]
                }
                return pairs[index][keyPath: keyPath]
            },
            set: { newValue in
                guard let index = pairs.firstIndex(where: { $0.id == pair.id }) else { return }
                pairs[index][keyPath: keyPath] = newValue
            }
        )
    }
}
