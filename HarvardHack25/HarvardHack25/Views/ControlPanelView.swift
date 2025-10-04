import SwiftUI

struct ControlPanelView: View {
    let requestHelper: (String) -> Void

    @State private var helperContext: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Helper Escalation")
                .font(.subheadline.weight(.semibold))
            HStack {
                TextField("Describe what you need", text: $helperContext)
                    .textFieldStyle(.roundedBorder)
                Button("Request") {
                    submitRequestIfNeeded()
                }
                .buttonStyle(.borderedProminent)
                .disabled(helperContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func submitRequestIfNeeded() {
        let trimmed = helperContext.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        requestHelper(trimmed)
        helperContext = ""
    }
}
