import SwiftUI

struct ControlPanelView: View {
    let requestHelper: (String) -> Void

    @State private var helperContext: String = ""
    @FocusState private var isFieldFocused: Bool

    private var isSubmitDisabled: Bool {
        helperContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Describe what you need", text: $helperContext, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.callout.weight(.medium))
                .foregroundStyle(.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
                .focused($isFieldFocused)
                .onSubmit(submitRequestIfNeeded)
                .accessibilityHint("Detail the situation to give the helper immediate context.")

            HStack(spacing: 12) {
                Button(action: submitRequestIfNeeded) {
                    Label("Send Helper Ping", systemImage: "paperplane.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSubmitDisabled)

                Spacer(minLength: 8)

                Text("Pinch again to enqueue another request if things change.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            if helperContext.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    isFieldFocused = true
                }
            }
        }
    }

    private func submitRequestIfNeeded() {
        let trimmed = helperContext.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        requestHelper(trimmed)
        helperContext = ""
        isFieldFocused = true
    }
}
