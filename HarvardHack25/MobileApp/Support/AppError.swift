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

public struct DetectedObject: Codable, Sendable, Identifiable {
    public struct SafetyInfo: Codable, Sendable {
        public let expirationDate: Date?
        public let allergenWarnings: [String]
        public let hazards: [String]
        public let medicationDetails: String?
        public let critical: Bool

        public init(
            expirationDate: Date? = nil,
            allergenWarnings: [String] = [],
            hazards: [String] = [],
            medicationDetails: String? = nil,
            critical: Bool = false
        ) {
            self.expirationDate = expirationDate
            self.allergenWarnings = allergenWarnings
            self.hazards = hazards
            self.medicationDetails = medicationDetails
            self.critical = critical
        }
    }

    public struct BoundingBox: Codable, Sendable {
        public let origin: SIMD2<Double>
        public let size: SIMD2<Double>

        public init(origin: SIMD2<Double>, size: SIMD2<Double>) {
            self.origin = origin
            self.size = size
        }
    }

    public let id: UUID
    public let type: String
    public let name: String?
    public let confidence: Double
    public let safetyInfo: SafetyInfo
    public let boundingBox: BoundingBox?
    public let textualContext: [String]

    public init(
        id: UUID = UUID(),
        type: String,
        name: String? = nil,
        confidence: Double,
        safetyInfo: SafetyInfo = .init(),
        boundingBox: BoundingBox? = nil,
        textualContext: [String] = []
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.confidence = confidence
        self.safetyInfo = safetyInfo
        self.boundingBox = boundingBox
        self.textualContext = textualContext
    }

    public var hasCriticalSafetyInfo: Bool {
        safetyInfo.critical || !safetyInfo.allergenWarnings.isEmpty || !safetyInfo.hazards.isEmpty
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

public struct TrackedObjectState: Identifiable, Sendable {
    public let id: UUID
    public let detection: DetectedObject
    public let worldTransform: simd_float4x4
    public let lastUpdated: Date
    public var isGazed: Bool

    public init(
        detection: DetectedObject,
        worldTransform: simd_float4x4,
        lastUpdated: Date = Date(),
        isGazed: Bool = false
    ) {
        self.id = detection.id
        self.detection = detection
        self.worldTransform = worldTransform
        self.lastUpdated = lastUpdated
        self.isGazed = isGazed
    }

    public var worldPosition: SIMD3<Float> {
        SIMD3(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)
    }
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

public struct AudioQueueItem: Identifiable, Sendable {
    public enum Kind: Sendable {
        case description(AudioDescriptionPayload)
        case safety(SafetyAlertPayload)
    }

    public let id: UUID
    public let kind: Kind
    public let enqueuedAt: Date

    public init(kind: Kind, enqueuedAt: Date = Date()) {
        self.id = UUID()
        self.kind = kind
        self.enqueuedAt = enqueuedAt
    }
}
