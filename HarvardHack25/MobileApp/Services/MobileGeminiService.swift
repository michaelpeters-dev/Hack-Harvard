import Foundation

actor MobileGeminiService: DetectionProcessing {
    func analyze(images: [GeminiDetectionRequest.Image], sessionID: UUID) async throws -> GeminiDetectionResponse {
        throw AppError.notImplemented(feature: "Mobile Gemini inference")
    }
}
