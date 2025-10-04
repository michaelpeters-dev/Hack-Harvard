import Foundation

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
