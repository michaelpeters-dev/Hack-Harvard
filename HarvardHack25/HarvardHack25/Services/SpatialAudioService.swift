import Foundation

actor SpatialAudioService: SpatialAudioPlaying {
    private var queue: [AudioQueueItem] = []
    private var isPlaying = false

    func play(description: AudioDescriptionPayload) async {
        let item = AudioQueueItem(kind: .description(description))
        queue.append(item)
        await processQueue()
    }

    func interruptWith(alert: SafetyAlertPayload) async {
        queue.removeAll()
        queue.insert(AudioQueueItem(kind: .safety(alert)), at: 0)
        await processQueue(forceRestart: true)
    }

    private func processQueue(forceRestart: Bool = false) async {
        guard forceRestart || isPlaying == false else { return }
        guard let next = queue.first else {
            isPlaying = false
            return
        }

        isPlaying = true
        queue.removeFirst()
        do {
            try await play(item: next)
        } catch {
            // TODO: route error to telemetry sink once defined.
        }
        isPlaying = false
        await processQueue()
    }

    private func play(item: AudioQueueItem) async throws {
        switch item.kind {
        case .description(let payload):
            try await playSpatialAudio(text: payload.text, position: payload.worldPosition)
        case .safety(let payload):
            try await playAlert(message: payload.message, position: payload.worldPosition)
        }
    }

    private func playSpatialAudio(text: String, position: SIMD3<Float>) async throws {
        // TODO: wire into PHASE spatial audio engine with queued TTS output.
        throw AppError.notImplemented(feature: "Spatial audio playback")
    }

    private func playAlert(message: String, position: SIMD3<Float>) async throws {
        // TODO: play alert tone then synthesized message at given position.
        throw AppError.notImplemented(feature: "Safety alert spatial playback")
    }
}
