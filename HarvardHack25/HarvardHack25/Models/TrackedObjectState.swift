import Foundation
import simd

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
