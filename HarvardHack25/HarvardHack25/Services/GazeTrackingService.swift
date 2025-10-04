import Foundation
import Combine

@MainActor
final class GazeTrackingService: ObservableObject, GazeTrackingProviding {
    @Published private(set) var currentGazedObjectID: UUID?

    private var trackingTask: Task<Void, Never>?

    func startTracking() async throws {
        guard trackingTask == nil else { return }
        trackingTask = Task.detached(priority: .userInitiated) { [weak self] in
            await self?.pollGazeData()
        }
    }

    func stopTracking() async {
        trackingTask?.cancel()
        trackingTask = nil
        currentGazedObjectID = nil
    }

    private func pollGazeData() async {
        // TODO: Subscribe to visionOS eye-tracking API once available to third parties.
        while Task.isCancelled == false {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }
}
