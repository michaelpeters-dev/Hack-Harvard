import SwiftUI

struct CameraPreviewPlaceholder: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .gray.opacity(0.6)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.8))
                Text("Live preview not wired yet")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}
