import Foundation

public enum AppError: LocalizedError, Sendable {
    case notImplemented(feature: String)
    case serviceFailure(underlying: Error)
    case invalidState(reason: String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let feature):
            return "Feature not implemented: \(feature)"
        case .serviceFailure(let underlying):
            return "Service failure: \(underlying.localizedDescription)"
        case .invalidState(let reason):
            return "Invalid state: \(reason)"
        }
    }
}
