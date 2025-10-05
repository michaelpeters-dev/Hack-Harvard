import SwiftUI

struct GlassPanel<Content: View>: View {
    enum Tone { case neutral, success, warning, danger

        var accent: Color {
            switch self {
            case .neutral: return .white.opacity(0.28)
            case .success: return .green.opacity(0.55)
            case .warning: return .yellow.opacity(0.65)
            case .danger:  return .red.opacity(0.75)
            }
        }
        var highlight: Color {
            switch self {
            case .neutral: return .white.opacity(0.35)
            case .success: return .green.opacity(0.45)
            case .warning: return .yellow.opacity(0.50)
            case .danger:  return .red.opacity(0.55)
            }
        }
    }

    private let tone: Tone
    private let cornerRadius: CGFloat
    private let contentPadding: CGFloat           // ⬅️ NEW
    @ViewBuilder private let content: Content

    init(
        tone: Tone = .neutral,
        cornerRadius: CGFloat = 22,
        contentPadding: CGFloat = 20,             // ⬅️ NEW
        @ViewBuilder content: () -> Content
    ) {
        self.tone = tone
        self.cornerRadius = cornerRadius
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        content
            .padding(contentPadding)              // ⬅️ was hard-coded 20
            .background(glassBackground)
            .overlay(highlightOverlay)
            .shadow(color: .black.opacity(0.25), radius: 18, y: 12)
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(tone.accent.gradient)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
            )
            .compositingGroup()
            .background(glassEffect)
    }

    @ViewBuilder private var glassEffect: some View {
        #if os(visionOS)
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .glassBackgroundEffect()
        #else
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
        #endif
    }

    private var highlightOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(colors: [tone.highlight, .clear],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 1.2
            )
    }
}
