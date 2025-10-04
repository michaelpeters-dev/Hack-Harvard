import Foundation
import simd

public enum AppError: LocalizedError, Sendable {
    case notImplemented(feature: String)
    case serviceFailure(underlying: Error)
    case invalidState(reason: String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let feature):
            return "Feature not implemented: \(feature)"
        case .serviceFailure(let underlying):
            return "Service failure: \(underlying.localizedDescription)"
        case .invalidState(let reason):
            return "Invalid state: \(reason)"
        }
    }
}

public struct GeminiDetectionRequest: Codable, Sendable {
    public struct Image: Codable, Sendable {
        public let base64Data: String
        public let captureTimestamp: Date

        public init(base64Data: String, captureTimestamp: Date = Date()) {
            self.base64Data = base64Data
            self.captureTimestamp = captureTimestamp
        }
    }

    public let sessionID: UUID
    public let images: [Image]
    public let prompt: String

    public init(sessionID: UUID, images: [Image], prompt: String) {
        self.sessionID = sessionID
        self.images = images
        self.prompt = prompt
    }
}

public struct GeminiDetectionResponse: Codable, Sendable {
    public let objects: [DetectedObject]
    public let processedAt: Date

    public init(objects: [DetectedObject], processedAt: Date = Date()) {
        self.objects = objects
        self.processedAt = processedAt
    }
}

public protocol DetectionProcessing: Sendable {
    func analyze(images: [GeminiDetectionRequest.Image], sessionID: UUID) async throws -> GeminiDetectionResponse
}

public protocol StreamingSessionManaging: Sendable {
    func configureSession() async throws
    func startStreaming() async throws
    func stopStreaming() async
    func updateBitrate(_ bitrate: Int) async
}

public protocol GazeTrackingProviding: Sendable {
    var currentGazedObjectID: UUID? { get }
    func startTracking() async throws
    func stopTracking() async
}

public protocol SpatialAudioPlaying: Sendable {
    func play(description: AudioDescriptionPayload) async
    func interruptWith(alert: SafetyAlertPayload) async
}

public protocol HelperEscalationHandling: Sendable {
    func requestHelper(with reason: HelperPing.Reason) async throws
    func cancelPendingRequests() async
}

public struct HelperPing: Codable, Sendable {
    public enum Reason: Codable, Sendable {
        case lowConfidence(objectType: String, confidence: Double)
        case manualRequest(context: String)
    }

    public let requestID: UUID
    public let reason: Reason
    public let preferredLanguage: String

    public init(requestID: UUID = UUID(), reason: Reason, preferredLanguage: String = "en-US") {
        self.requestID = requestID
        self.reason = reason
        self.preferredLanguage = preferredLanguage
    }
}
