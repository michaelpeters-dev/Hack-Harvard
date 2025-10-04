import Foundation
import Combine

@MainActor
final class VisionStreamingService: ObservableObject, StreamingSessionManaging {
    @Published private(set) var isStreaming = false

    private let helperConnectionService: HelperConnectionService
    private var currentSessionID: UUID?

    init(helperConnectionService: HelperConnectionService) {
        self.helperConnectionService = helperConnectionService
    }

    func configureSession() async throws {
        guard currentSessionID == nil else { return }
        currentSessionID = UUID()
        // TODO: integrate WebRTC stack and signaling hooks.
    }

    func startStreaming() async throws {
        guard isStreaming == false else { return }
        guard currentSessionID != nil else {
            throw AppError.invalidState(reason: "Streaming requested before session configured")
        }
        isStreaming = true
        // TODO: start WebRTC video pipeline.
    }

    func stopStreaming() async {
        guard isStreaming else { return }
        isStreaming = false
        // TODO: tear down WebRTC resources.
    }

    func updateBitrate(_ bitrate: Int) async {
        guard isStreaming else { return }
        // TODO: propagate bitrate update to encoder.
    }
}
