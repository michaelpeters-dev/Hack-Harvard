import Foundation
import Combine

@MainActor
final class ImmersiveViewModel: ObservableObject {
    @Published private(set) var objects: [TrackedObjectState] = []
    @Published private(set) var isStreaming = false
    @Published private(set) var lastErrorDescription: String?

    private let streamingService: VisionStreamingService
    private let objectTrackingService: ObjectTrackingService
    private let spatialAudioService: SpatialAudioService
    private let helperConnectionService: HelperConnectionService
    private var cancellables: Set<AnyCancellable> = []
    private var announcedSafetyObjects: Set<UUID> = []

    init(
        streamingService: VisionStreamingService,
        objectTrackingService: ObjectTrackingService,
        spatialAudioService: SpatialAudioService,
        helperConnectionService: HelperConnectionService
    ) {
        self.streamingService = streamingService
        self.objectTrackingService = objectTrackingService
        self.spatialAudioService = spatialAudioService
        self.helperConnectionService = helperConnectionService
        bind()
    }

    func onAppear() {
        Task {
            do {
                try await streamingService.configureSession()
                try await streamingService.startStreaming()
                isStreaming = true
                objectTrackingService.startSession()
            } catch {
                lastErrorDescription = error.localizedDescription
            }
        }
    }

    func onDisappear() {
        Task {
            await streamingService.stopStreaming()
            objectTrackingService.stopSession()
            isStreaming = false
        }
    }

    func requestHelperManually(context: String) {
        Task {
            do {
                try await helperConnectionService.requestHelper(with: .manualRequest(context: context))
            } catch {
                lastErrorDescription = error.localizedDescription
            }
        }
    }

    private func bind() {
        objectTrackingService.$trackedObjects
            .receive(on: DispatchQueue.main)
            .sink { [weak self] objects in
                self?.objects = objects
                Task { await self?.handleAudioUpdates(for: objects) }
            }
            .store(in: &cancellables)

        streamingService.$isStreaming
            .receive(on: DispatchQueue.main)
            .assign(to: &$isStreaming)
    }

    private func handleAudioUpdates(for objects: [TrackedObjectState]) async {
        for object in objects {
            let position = object.worldPosition
            if object.detection.hasCriticalSafetyInfo, announcedSafetyObjects.contains(object.id) == false {
                announcedSafetyObjects.insert(object.id)
                let alert = SafetyAlertPayload(
                    objectID: object.id,
                    message: safetyMessage(for: object.detection),
                    worldPosition: position
                )
                await spatialAudioService.interruptWith(alert: alert)
                continue
            }

            if object.isGazed {
                let description = AudioDescriptionPayload(
                    text: descriptionText(for: object.detection),
                    objectID: object.id,
                    worldPosition: position,
                    priority: .elevated
                )
                await spatialAudioService.play(description: description)
            }
        }
    }

    private func safetyMessage(for detection: DetectedObject) -> String {
        var components: [String] = []
        if let expiration = detection.safetyInfo.expirationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            components.append("Expiration: \(formatter.string(from: expiration))")
        }
        components.append(contentsOf: detection.safetyInfo.allergenWarnings.map { "Allergen: \($0)" })
        components.append(contentsOf: detection.safetyInfo.hazards.map { "Hazard: \($0)" })
        if let medication = detection.safetyInfo.medicationDetails {
            components.append(medication)
        }
        if components.isEmpty {
            components.append("Critical safety information detected")
        }
        return components.joined(separator: ". ")
    }

    private func descriptionText(for detection: DetectedObject) -> String {
        var pieces: [String] = []
        pieces.append(detection.name ?? detection.type.capitalized)
        if detection.textualContext.isEmpty == false {
            pieces.append(detection.textualContext.joined(separator: ". "))
        }
        return pieces.joined(separator: ". ")
    }
}
