import SwiftUI

struct ScanAndDescribeControl: View {
    @EnvironmentObject private var viewModel: ImmersiveViewModel
    @State private var status: Status = .idle

    private enum Layout {
        static let containerCornerRadius: CGFloat = 14
        static let previewCornerRadius: CGFloat = 12
        static let previewPadding: CGFloat = 10
        static let placeholderIconSize: CGFloat = 58
        static let placeholderPadding: CGFloat = 52
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Scan & Preview")
                .font(.subheadline.weight(.semibold))

            ZStack {
                RoundedRectangle(cornerRadius: Layout.containerCornerRadius, style: .continuous)
                    .fill(.white.opacity(0.06))

                if let preview = viewModel.latestPreview {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Layout.previewCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.previewCornerRadius, style: .continuous)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )
                        .padding(Layout.previewPadding)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: Layout.placeholderIconSize, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("No preview yet")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Layout.placeholderPadding)
                }
            }
            .frame(minHeight: 360, maxHeight: 520)

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
