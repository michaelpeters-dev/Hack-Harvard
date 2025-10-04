import Foundation
import Combine
import simd

@MainActor
final class ObjectTrackingService: ObservableObject {
    @Published private(set) var trackedObjects: [TrackedObjectState] = []

    private let geminiService: any DetectionProcessing
    private let gazeTrackingService: any GazeTrackingProviding
    private var detectionTask: Task<Void, Never>?

    init(geminiService: any DetectionProcessing, gazeTrackingService: any GazeTrackingProviding) {
        self.geminiService = geminiService
        self.gazeTrackingService = gazeTrackingService
    }

    func startSession() {
        // TODO: Hook up ARKit session management once the target links ARKit.
    }

    func stopSession() {
        detectionTask?.cancel()
        detectionTask = nil
        trackedObjects.removeAll()
    }

    func ingestFrame(_ frame: Any) {
        _ = frame
        detectionTask?.cancel()
        detectionTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await self.geminiService.analyze(images: [], sessionID: UUID())
                await MainActor.run {
                    self.updateTrackedObjects(with: response)
                }
            } catch {
                // TODO: surface error to telemetry once pipeline is wired.
            }
        }
    }

    private func updateTrackedObjects(with response: GeminiDetectionResponse) {
        trackedObjects = response.objects.map { detection in
            var state = TrackedObjectState(
                detection: detection,
                worldTransform: matrix_identity_float4x4
            )
            state.isGazed = (detection.id == gazeTrackingService.currentGazedObjectID)
            return state
        }
    }
}
