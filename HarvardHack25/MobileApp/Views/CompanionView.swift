import SwiftUI

struct CompanionView: View {
    @EnvironmentObject private var viewModel: CompanionViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                CameraPreviewPlaceholder()
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .background(Color.black.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.4), lineWidth: 1)
                    )

                StatusView(state: viewModel.sessionState, lastError: viewModel.lastErrorDescription)

                HelperView(onRetry: viewModel.retryConnection)

                Spacer()
            }
            .padding()
            .navigationTitle("Vision Pro Companion")
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}
