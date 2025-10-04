import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @EnvironmentObject private var viewModel: ImmersiveViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            RealityView { _ in
                // TODO: add anchors and 3D overlays once ARKit pipeline is wired.
            }
            .onAppear { viewModel.onAppear() }
            .onDisappear { viewModel.onDisappear() }

            overlayPanel
                .padding()
        }
    }

    private var overlayPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.isStreaming ? "Demo Mode: Ready" : "Demo Mode: Stopped")
                .font(.headline)
                .foregroundStyle(viewModel.isStreaming ? .green : .red)

            Text("Endpoint: \(viewModel.endpointDescription)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let error = viewModel.lastErrorDescription {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 10) {
                Button("Ping Local Server") { viewModel.pingServer() }
                    .buttonStyle(.bordered)
                Text("Ping: \(viewModel.lastPingStatus)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                viewModel.scanOnceHardcoded()
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isBusy { ProgressView().scaleEffect(0.8) }
                    Text(viewModel.isBusy ? "Scanning…" : "Scan → POST (Local)")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isBusy)

            VStack(alignment: .leading, spacing: 6) {
                Text("LAN caption: \(viewModel.lastLANCaption)")
                    .font(.caption).foregroundStyle(.secondary)
                Text("JPEG bytes: \(viewModel.lastJPEGBytes)  |  Crop: \(viewModel.lastCropSide)x\(viewModel.lastCropSide)")
                    .font(.caption).foregroundStyle(.secondary)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.objects) { object in
                        ObjectOverlayView(object: object)
                    }
                }
            }
            .frame(maxHeight: 240)
        }
        .frame(maxWidth: 360)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

