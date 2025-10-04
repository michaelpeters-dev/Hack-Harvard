import SwiftUI

struct AlertView: View {
    let detection: DetectedObject

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Safety Alert")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
            }
            ForEach(alertMessages, id: \.self) { message in
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.white)
            }
        }
        .padding(8)
        .background(.red.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.red, lineWidth: 1)
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
