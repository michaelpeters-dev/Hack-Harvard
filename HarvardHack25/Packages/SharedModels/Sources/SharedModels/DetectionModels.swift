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
