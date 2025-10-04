import SwiftUI

struct HelperView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Helper Escalation")
                .font(.headline)
            Text("When AI confidence drops, we auto-escalate to a human helper. Tap below to retry the connection manually.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(action: onRetry) {
                Label("Retry Helper Connection", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
