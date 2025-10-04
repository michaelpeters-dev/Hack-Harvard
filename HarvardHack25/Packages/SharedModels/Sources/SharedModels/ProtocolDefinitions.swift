import Foundation

/// Contract for components capable of sending video frames to remote peers.
public protocol StreamingSessionManaging: Sendable {
    func configureSession() async throws
    func startStreaming() async throws
    func stopStreaming() async
    func updateBitrate(_ bitrate: Int) async
}

/// Wrapper for AI detection pipelines so Gemini can be swapped for local models.
public protocol DetectionProcessing: Sendable {
    func analyze(images: [GeminiDetectionRequest.Image], sessionID: UUID) async throws -> GeminiDetectionResponse
}

/// Abstraction for gaze tracking sources to enable test doubles.
public protocol GazeTrackingProviding: Sendable {
    var currentGazedObjectID: UUID? { get }
    func startTracking() async throws
    func stopTracking() async
}

/// Handles spatialized audio output with prioritization logic.
public protocol SpatialAudioPlaying: Sendable {
    func play(description: AudioDescriptionPayload) async
    func interruptWith(alert: SafetyAlertPayload) async
}

/// Dispatches helper escalation events whether triggered manually or automatically.
public protocol HelperEscalationHandling: Sendable {
    func requestHelper(with reason: HelperPing.Reason) async throws
    func cancelPendingRequests() async
}

/// Payload describing audio content to be played in 3D space.
public struct AudioDescriptionPayload: Sendable {
    public enum Priority: Sendable {
        case normal
        case elevated
    }

    public let text: String
    public let objectID: UUID
    public let worldPosition: SIMD3<Float>
    public let priority: Priority

    public init(text: String, objectID: UUID, worldPosition: SIMD3<Float>, priority: Priority) {
        self.text = text
        self.objectID = objectID
        self.worldPosition = worldPosition
        self.priority = priority
    }
}

/// Payload describing a safety-critical alert.
public struct SafetyAlertPayload: Sendable {
    public let objectID: UUID
    public let message: String
    public let worldPosition: SIMD3<Float>

    public init(objectID: UUID, message: String, worldPosition: SIMD3<Float>) {
        self.objectID = objectID
        self.message = message
        self.worldPosition = worldPosition
    }
}
