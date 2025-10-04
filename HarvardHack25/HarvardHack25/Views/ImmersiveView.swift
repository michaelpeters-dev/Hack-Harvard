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
            Text(viewModel.isStreaming ? "Streaming: Active" : "Streaming: Stopped")
                .font(.headline)
                .foregroundStyle(viewModel.isStreaming ? .green : .red)
            if let error = viewModel.lastErrorDescription {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            ControlPanelView(requestHelper: viewModel.requestHelperManually)
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
