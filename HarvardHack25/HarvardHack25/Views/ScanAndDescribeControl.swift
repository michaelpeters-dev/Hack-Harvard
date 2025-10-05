import SwiftUI

struct ScanAndDescribeControl: View {
    @EnvironmentObject private var viewModel: ImmersiveViewModel
    @State private var status: Status = .idle

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Scan & Preview")
                .font(.subheadline.weight(.semibold))

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.06))

                if let preview = viewModel.latestPreview {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )
                        .padding(6)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("No preview yet")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(32)
                }
            }
            .frame(maxHeight: 240)

            Button(action: startScan) {
                Label("Scan Latest Photo", systemImage: "viewfinder.rectangular")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isBusy)

            HStack(spacing: 8) {
                statusIcon
                Text(status.message)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.latestPreview)
        .animation(.easeInOut(duration: 0.2), value: status)
        .onChange(of: viewModel.isBusy) { _, isBusy in
            if isBusy == false {
                status = .idle
            }
        }
        .onChange(of: viewModel.lastLANCaption) { _ in
            status = .idle
        }
    }

    private func startScan() {
        guard viewModel.isBusy == false else { return }
        status = .processing
        viewModel.processLatestPhotoNow()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            status = .waitingForCaption
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .idle:
            Image(systemName: "sparkles")
                .foregroundStyle(.secondary)
        case .processing:
            ProgressView().progressViewStyle(.circular)
        case .waitingForCaption:
            Image(systemName: "waveform")
                .foregroundStyle(.cyan)
        }
    }

    private enum Status: Equatable {
        case idle
        case processing
        case waitingForCaption

        var message: String {
            switch self {
            case .idle:
                return "Tap scan to refresh the preview and caption."
            case .processing:
                return "Processing latest photo…"
            case .waitingForCaption:
                return "Generating caption and audio."
            }
        }
    }
}
