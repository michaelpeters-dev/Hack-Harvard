import SwiftUI

struct LatestPhotoPreview: View {
    @EnvironmentObject private var viewModel: ImmersiveViewModel
    @State private var status: String = "Tap to load the latest photo."

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest Photo")
                .font(.subheadline.weight(.semibold))

            ZStack {
                if let ui = viewModel.latestPreview {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.06))
                        .overlay(Text("No preview").foregroundStyle(.secondary))
                        .frame(height: 140)
                }
            }

            Button {
                status = "Loading…"
                viewModel.processLatestPhotoNow()
                // UI will update via viewModel.latestPreview and diagnostics
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    status = "Preview ready."
                }
            } label: {
                Label("Show Latest Photo", systemImage: "photo.on.rectangle")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
