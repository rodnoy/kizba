import SwiftUI

@MainActor
struct SearchOverlayView: View {
    @Bindable var model: SearchModel
    let onSelect: (SearchResult) -> Void
    let onDismiss: () -> Void

    @Environment(\.theme) private var theme
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ZStack {
            theme.colors.scrim
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                    model.cancel()
                }

            VStack(alignment: .leading, spacing: theme.spacing.md) {
                TextField("Search…", text: $model.query)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFieldFocused)
                    .accessibilityLabel("Search")
                    .onChange(of: model.query) { _, newValue in
                        model.updateQuery(newValue)
                    }
                    .onSubmit {
                        if let result = model.selectCurrent() ?? model.results.first {
                            onSelect(result)
                        }
                    }

                if model.isLoading {
                    ProgressView()
                }

                ScrollView {
                    LazyVStack(spacing: theme.spacing.xs) {
                        ForEach(Array(model.results.enumerated()), id: \.element.id) { index, result in
                            Button {
                                onSelect(result)
                            } label: {
                                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                    Text(result.title)
                                        .foregroundStyle(theme.colors.onSurface)

                                    if let subtitle = result.subtitle {
                                        Text(subtitle)
                                            .font(theme.typography.caption)
                                            .foregroundStyle(theme.colors.onSurfaceMuted)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, theme.spacing.sm)
                                .padding(.vertical, theme.spacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: theme.radius.sm)
                                        .fill(model.selectedIndex == index ? theme.colors.accentMuted : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(result.title)
                        }
                    }
                }
                .frame(maxHeight: 320)

                Button("Dismiss Search") {
                    onDismiss()
                    model.cancel()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .labelsHidden()
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
            }
            .padding(theme.spacing.lg)
            .frame(minWidth: 480, maxWidth: 640)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
            .shadow(radius: 14)
        }
        .onAppear {
            isFieldFocused = true
        }
    }
}
