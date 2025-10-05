import SwiftUI

#if !os(visionOS)

@MainActor
final class ImmersiveViewModel: ObservableObject {
    init(helperService: HelperEscalationHandling? = nil, streamingService: VisionStreamingService? = nil) {}
}

struct ImmersiveView: View {
    var body: some View {
        Text("Vision-only experience not available on this platform.")
            .multilineTextAlignment(.center)
            .padding()
    }
}

#endif
