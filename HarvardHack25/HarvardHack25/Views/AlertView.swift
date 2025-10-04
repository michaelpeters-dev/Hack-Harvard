import SwiftUI

struct AlertView: View {
    let detection: DetectedObject

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text("Safety Alert")
                    .font(.callout.weight(.semibold))
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3.weight(.bold))
            }
            .foregroundStyle(.red)

            ForEach(alertMessages, id: \.self) { message in
                Text(message)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(alertBackground)
        .overlay(alertBorder)
        .shadow(color: .red.opacity(0.3), radius: 6, y: 4)
    }

    private var alertBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.red.opacity(0.45), Color.red.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.red.opacity(0.12))
            )
            .compositingGroup()
    }

    private var alertBorder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [Color.red.opacity(0.55), Color.white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.25
            )
    }

    private var alertMessages: [String] {
        var messages: [String] = []
        if let date = detection.safetyInfo.expirationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            messages.append("Expiration: \(formatter.string(from: date))")
        }
        messages.append(contentsOf: detection.safetyInfo.allergenWarnings.map { "Allergen: \($0)" })
        messages.append(contentsOf: detection.safetyInfo.hazards.map { "Hazard: \($0)" })
        if let medication = detection.safetyInfo.medicationDetails {
            messages.append(medication)
        }
        return messages.isEmpty ? ["Safety-critical detail detected"] : messages
    }
}
