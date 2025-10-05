import SwiftUI

struct HelperStatusIndicator: View {
    let status: ImmersiveViewModel.HelperStatus

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: iconName)
                .symbolVariant(iconVariant)
                .foregroundStyle(iconColor)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(borderStroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
}

private extension HelperStatusIndicator {
    var title: String {
        switch status {
        case .idle:
            return "Idle"
        case .sending:
            return "Contacting helper…"
        case .sent:
            return "Request sent"
        case .failed:
            return "Failed to send"
        case .simulatedAcknowledged:
            return "Helper acknowledged"
        }
    }

    var subtitle: String? {
        switch status {
        case .simulatedAcknowledged(let context):
            return context
        default:
            return nil
        }
    }

    var iconName: String {
        switch status {
        case .idle:
            return "person"
        case .sending:
            return "paperplane"
        case .sent:
            return "checkmark.circle"
        case .failed:
            return "xmark.octagon"
        case .simulatedAcknowledged:
            return "person.wave.2"
        }
    }

    var iconVariant: SymbolVariants {
        switch status {
        case .sent, .failed:
            return .fill
        default:
            return .none
        }
    }

    var iconColor: Color {
        switch status {
        case .idle:
            return .secondary
        case .sending:
            return .orange
        case .sent, .simulatedAcknowledged:
            return .green
        case .failed:
            return .red
        }
    }

    var backgroundFill: some ShapeStyle {
        switch status {
        case .idle:
            return Color.white.opacity(0.04)
        case .sending:
            return Color.orange.opacity(0.08)
        case .sent, .simulatedAcknowledged:
            return Color.green.opacity(0.08)
        case .failed:
            return Color.red.opacity(0.10)
        }
    }

    var borderStroke: some ShapeStyle {
        switch status {
        case .idle:
            return Color.white.opacity(0.12)
        case .sending:
            return Color.orange.opacity(0.20)
        case .sent, .simulatedAcknowledged:
            return Color.green.opacity(0.22)
        case .failed:
            return Color.red.opacity(0.25)
        }
    }

    var accessibilityLabel: String {
        if let subtitle = subtitle {
            return "Helper status: \(title). \(subtitle)"
        } else {
            return "Helper status: \(title)"
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        HelperStatusIndicator(status: .idle)
        HelperStatusIndicator(status: .sending)
        HelperStatusIndicator(status: .sent)
        HelperStatusIndicator(status: .failed)
        HelperStatusIndicator(status: .simulatedAcknowledged(context: "Looking for a helper near you."))
    }
    .padding()
}
