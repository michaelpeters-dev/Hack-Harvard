import Foundation
import Combine

@MainActor
final class CompanionViewModel: ObservableObject {
    @Published private(set) var sessionState: StreamSessionState
    @Published private(set) var lastErrorDescription: String?

    private let cameraService: CameraService
    private let streamingService: MobileStreamingService
    private let geminiService: MobileGeminiService
    private var cancellables: Set<AnyCancellable> = []

    init(
        cameraService: CameraService,
        streamingService: MobileStreamingService,
        geminiService: MobileGeminiService
    ) {
        self.cameraService = cameraService
        self.streamingService = streamingService
        self.geminiService = geminiService
        self.sessionState = streamingService.sessionState
        bind()
    }

    func onAppear() {
        Task {
            do {
                try await streamingService.configureSession()
                try await streamingService.startStreaming()
                cameraService.start()
            } catch {
                lastErrorDescription = error.localizedDescription
            }
        }
    }

    func onDisappear() {
        Task {
            await streamingService.stopStreaming()
            cameraService.stop()
        }
    }

    func retryConnection() {
        Task {
            do {
                try await streamingService.startStreaming()
            } catch {
                lastErrorDescription = error.localizedDescription
            }
        }
    }

    private func bind() {
        streamingService.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.sessionState = state
            }
            .store(in: &cancellables)
    }
}
