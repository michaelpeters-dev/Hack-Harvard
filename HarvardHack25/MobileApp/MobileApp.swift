import SwiftUI

@main
struct MobileCompanionApp: App {
    @StateObject private var dependencies = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies)
        }
    }
}

final class DependencyContainer: ObservableObject {
    let cameraService: CameraService
    let streamingService: MobileStreamingService
    let geminiService: MobileGeminiService

    init() {
        let streamingService = MobileStreamingService()
        self.streamingService = streamingService

        let cameraService = CameraService(streamingService: streamingService)
        self.cameraService = cameraService

        self.geminiService = MobileGeminiService()
    }
}

struct RootView: View {
    @EnvironmentObject private var dependencies: DependencyContainer

    var body: some View {
        CompanionView()
            .environmentObject(
                CompanionViewModel(
                    cameraService: dependencies.cameraService,
                    streamingService: dependencies.streamingService,
                    geminiService: dependencies.geminiService
                )
            )
    }
}
