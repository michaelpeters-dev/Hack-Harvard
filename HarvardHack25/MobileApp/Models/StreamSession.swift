import Foundation

enum StreamConnectionState: Equatable, Sendable {
    case idle
    case connecting
    case streaming
    case reconnecting(attempt: Int)
    case failed(error: String)
}

struct StreamSessionState: Sendable {
    var id: UUID = UUID()
    var connectionState: StreamConnectionState = .idle
    var lastBitrate: Int?
    var lastLatencyMeasurement: TimeInterval?
}
