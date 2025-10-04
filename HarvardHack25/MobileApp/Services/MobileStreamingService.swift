import Foundation
import Combine

@MainActor
final class MobileStreamingService: ObservableObject, StreamingSessionManaging {
    @Published private(set) var sessionState = StreamSessionState()

    private var frameBuffer: [CameraFrame] = []
    private let maxBufferSize = 6

    func configureSession() async throws {
        guard sessionState.connectionState == .idle else { return }
        sessionState.connectionState = .connecting
        // TODO: configure WebRTC peer connection and signaling.
    }

    func startStreaming() async throws {
        switch sessionState.connectionState {
        case .idle:
            try await configureSession()
        case .connecting, .reconnecting:
            break
        case .streaming:
            return
        case .failed:
            sessionState = StreamSessionState()
            try await configureSession()
        }
        sessionState.connectionState = .streaming
    }

    func stopStreaming() async {
        sessionState.connectionState = .idle
        frameBuffer.removeAll()
        // TODO: tear down WebRTC connection cleanly.
    }

    func updateBitrate(_ bitrate: Int) async {
        sessionState.lastBitrate = bitrate
        // TODO: apply bitrate to encoder once integrated.
    }

    func enqueue(frame: CameraFrame) async {
        guard sessionState.connectionState == .streaming else { return }
        if frameBuffer.count >= maxBufferSize {
            frameBuffer.removeFirst()
        }
        frameBuffer.append(frame)
        await flushFrames()
    }

    private func flushFrames() async {
        guard sessionState.connectionState == .streaming else { return }
        while frameBuffer.isEmpty == false {
            let frame = frameBuffer.removeFirst()
            do {
                try await send(frame: frame)
            } catch {
                sessionState.connectionState = .failed(error: error.localizedDescription)
                break
            }
        }
    }

    private func send(frame: CameraFrame) async throws {
        // TODO: encode and send frame over WebRTC data channel.
        throw AppError.notImplemented(feature: "WebRTC frame transmission")
    }
}
