import Foundation
import simd

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
