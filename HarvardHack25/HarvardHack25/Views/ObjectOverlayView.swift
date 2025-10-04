import SwiftUI

struct ObjectOverlayView: View {
    let object: TrackedObjectState

    private var isVisible: Bool {
        object.isGazed || object.detection.hasCriticalSafetyInfo
    }

    private var headlineColor: Color {
        object.detection.hasCriticalSafetyInfo ? .yellow : .primary
    }

    var body: some View {
        Group {
            if isVisible {
                GlassPanel(tone: object.detection.hasCriticalSafetyInfo ? .warning : .neutral, cornerRadius: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        header
                        subtitle

                        if object.detection.hasCriticalSafetyInfo {
                            AlertView(detection: object.detection)
                        } else if let summary = contextualSummary {
                            Text(summary)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.secondary)
                                .lineSpacing(2)
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(object.isGazed ? Color.cyan.opacity(0.7) : Color.clear, lineWidth: 2)
                        .shadow(color: object.isGazed ? Color.cyan.opacity(0.3) : .clear, radius: 8, y: 4)
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isVisible)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(object.detection.name ?? object.detection.type.capitalized)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(headlineColor)
                Text(object.detection.type.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.9)
            }

            Spacer(minLength: 8)

            ConfidencePill(confidence: object.detection.confidence)
        }
    }

    private var subtitle: some View {
        HStack(spacing: 8) {
            Image(systemName: object.isGazed ? "eye.fill" : "timer")
                .font(.caption.weight(.bold))
                .foregroundStyle(object.isGazed ? .blue : .secondary)
            Text(object.isGazed ? "Focused" : "Updated \(relativeTimestamp)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var contextualSummary: String? {
        let trimmed = object.detection.textualContext
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        return trimmed.isEmpty ? nil : trimmed.joined(separator: ". ")
    }

    private var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: object.lastUpdated, relativeTo: .now)
    }
}

private struct ConfidencePill: View {
    let confidence: Double

    private var percentage: Int { Int((confidence * 100).rounded()) }

    private var pillGradient: LinearGradient {
        let start = Color.white.opacity(0.18)
        let end = Color.blue.opacity(0.55)
        return LinearGradient(colors: [start, end], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "shield.checkerboard")
                .font(.caption.weight(.bold))
            Text("\(percentage)%")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(pillGradient)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
    }
}
