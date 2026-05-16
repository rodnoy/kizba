import SwiftUI

/// Animated placeholder rectangle for loading states. Renders a sunken
/// rounded rectangle with a moving lighter-tinted gradient overlay; when
/// `accessibilityReduceMotion` is set, the gradient and animation are
/// dropped entirely and only the static base remains, so users who
/// suppress motion still see the placeholder shape.
public struct LoadingShimmer: View {
    private let cornerRadius: CGFloat
    private let width: CGFloat?
    private let height: CGFloat

    public init(cornerRadius: CGFloat = 8, width: CGFloat? = nil, height: CGFloat = 16) {
        self.cornerRadius = cornerRadius
        self.width = width
        self.height = height
    }

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return shape
            .fill(theme.colors.surfaceSunken)
            .frame(width: width, height: height)
            .overlay {
                if !reduceMotion {
                    let p1 = min(max(phase, 0), 1)
                    let p2 = min(max(phase + 0.25, 0), 1)
                    let p3 = min(max(phase + 0.5, 0), 1)
                    let p2ordered = max(p2, p1)
                    let p3ordered = max(p3, p2ordered)

                    shape
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: p1),
                                    .init(color: theme.colors.surfaceHover, location: p2ordered),
                                    .init(color: .clear, location: p3ordered)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .allowsHitTesting(false)
                }
            }
            .clipShape(shape)
            .accessibilityHidden(true)
            .onAppear {
                guard !reduceMotion else { return }
                let animation = theme.motion.animation(.standard, reduceMotion: false)?
                    .repeatForever(autoreverses: false)
                    .speed(0.5)
                withAnimation(animation) {
                    phase = 1
                }
            }
    }
}
