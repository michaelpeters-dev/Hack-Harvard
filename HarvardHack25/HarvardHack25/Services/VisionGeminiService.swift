import Foundation

actor VisionGeminiService: DetectionProcessing {
    private let helperConnectionService: HelperConnectionService
    private let apiClient: GeminiAPIClient
    private let confidenceThreshold: Double = 0.7

    init(helperConnectionService: HelperConnectionService, apiClient: GeminiAPIClient = DefaultGeminiAPIClient()) {
        self.helperConnectionService = helperConnectionService
        self.apiClient = apiClient
    }

    func analyze(images: [GeminiDetectionRequest.Image], sessionID: UUID) async throws -> GeminiDetectionResponse {
        let request = GeminiDetectionRequest(
            sessionID: sessionID,
            images: images,
            prompt: type(of: apiClient).defaultPrompt
        )

        let response = try await apiClient.performDetection(request: request)
        try await evaluateConfidence(for: response)
        return response
    }

    private func evaluateConfidence(for response: GeminiDetectionResponse) async throws {
        for object in response.objects where object.confidence < confidenceThreshold {
            try await helperConnectionService.requestHelper(with: .lowConfidence(objectType: object.type, confidence: object.confidence))
        }
    }
}

protocol GeminiAPIClient {
    static var defaultPrompt: String { get }
    func performDetection(request: GeminiDetectionRequest) async throws -> GeminiDetectionResponse
}

struct DefaultGeminiAPIClient: GeminiAPIClient {
    static let defaultPrompt: String = """
    Identify all objects, text, and important information in this image.
    Prioritize expiration dates, allergen warnings, safety hazards, medication info, and relevant text.
    Provide structured output with confidence scores for each detection.
    """

    func performDetection(request: GeminiDetectionRequest) async throws -> GeminiDetectionResponse {
        throw AppError.notImplemented(feature: "Gemini API integration")
    }
}
