import Foundation

// MARK: - Supporting Types

actor HelperConnectionService: HelperEscalationHandling {
    private var pendingRequests: [UUID: HelperPing.Reason] = [:]

    func requestHelper(with reason: HelperPing.Reason) async throws {
        let requestID = UUID()
        pendingRequests[requestID] = reason
        let ping = HelperPing(requestID: requestID, reason: reason)
        try await sendPingToNetwork(ping)
    }

    func cancelPendingRequests() async {
        pendingRequests.removeAll()
        // TODO: notify helper network about cancellation when API spec is available.
    }

    private func sendPingToNetwork(_ ping: HelperPing) async throws {
        // TODO: integrate with helper network signaling (WebSocket or REST).
        throw AppError.notImplemented(feature: "Helper network integration")
    }
}
