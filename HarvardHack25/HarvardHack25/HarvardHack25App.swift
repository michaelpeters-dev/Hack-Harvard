import SwiftUI
import Combine

@main
struct VisionProApp: App {
    @StateObject private var dependencies = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            ImmersiveRootView()
                .environmentObject(dependencies)
        }
        .defaultSize(width: 800, height: 600)
    }
}

final class DependencyContainer: ObservableObject {
    let streamingService: VisionStreamingService
    let geminiService: VisionGeminiService
    let objectTrackingService: ObjectTrackingService
    let spatialAudioService: SpatialAudioService
    let gazeTrackingService: GazeTrackingService
    let helperConnectionService: HelperConnectionService
    let immersiveViewModel: ImmersiveViewModel

    init() {
        let helperConnectionService = HelperConnectionService()
        self.helperConnectionService = helperConnectionService

        let geminiService = VisionGeminiService(helperConnectionService: helperConnectionService)
        self.geminiService = geminiService

        let spatialAudioService = SpatialAudioService()
        self.spatialAudioService = spatialAudioService

        let gazeTrackingService = GazeTrackingService()
        self.gazeTrackingService = gazeTrackingService

        let objectTrackingService = ObjectTrackingService(
            geminiService: geminiService,
            gazeTrackingService: gazeTrackingService
        )
        self.objectTrackingService = objectTrackingService

        let streamingService = VisionStreamingService(
            helperConnectionService: helperConnectionService
        )
        self.streamingService = streamingService

        self.immersiveViewModel = ImmersiveViewModel(
            streamingService: streamingService,
            objectTrackingService: objectTrackingService,
            spatialAudioService: spatialAudioService,
            helperConnectionService: helperConnectionService
        )
    }
}

struct ImmersiveRootView: View {
    @EnvironmentObject private var dependencies: DependencyContainer

    var body: some View {
        ImmersiveView()
            .environmentObject(dependencies.immersiveViewModel)
    }
}
