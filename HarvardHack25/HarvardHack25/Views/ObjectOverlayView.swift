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
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(object.detection.name ?? object.detection.type.capitalized)
                            .font(.headline)
                            .foregroundStyle(headlineColor)
                        Spacer()
                        Text(String(format: "%.0f%%", object.detection.confidence * 100))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if object.detection.hasCriticalSafetyInfo {
                        AlertView(detection: object.detection)
                    } else {
                        Text(object.detection.textualContext.joined(separator: ". "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(object.isGazed ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isVisible)
    }
}
