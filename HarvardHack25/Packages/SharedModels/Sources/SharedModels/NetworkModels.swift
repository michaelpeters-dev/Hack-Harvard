import Foundation

/// Represents the base envelope exchanged during WebRTC signaling.
public struct SignalingEnvelope: Codable, Sendable {
    public enum Payload: Codable, Sendable {
        case offer(SessionDescription)
        case answer(SessionDescription)
        case iceCandidate(IceCandidate)
        case helperPing(HelperPing)
        case helperAck(HelperAck)

        private enum CodingKeys: String, CodingKey {
            case type
            case offer
            case answer
            case candidate
            case helperPing
            case helperAck
        }

        private enum PayloadType: String, Codable {
            case offer
            case answer
            case iceCandidate
            case helperPing
            case helperAck
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(PayloadType.self, forKey: .type)
            switch type {
            case .offer:
                self = .offer(try container.decode(SessionDescription.self, forKey: .offer))
            case .answer:
                self = .answer(try container.decode(SessionDescription.self, forKey: .answer))
            case .iceCandidate:
                self = .iceCandidate(try container.decode(IceCandidate.self, forKey: .candidate))
            case .helperPing:
                self = .helperPing(try container.decode(HelperPing.self, forKey: .helperPing))
            case .helperAck:
                self = .helperAck(try container.decode(HelperAck.self, forKey: .helperAck))
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .offer(let description):
                try container.encode(PayloadType.offer, forKey: .type)
                try container.encode(description, forKey: .offer)
            case .answer(let description):
                try container.encode(PayloadType.answer, forKey: .type)
                try container.encode(description, forKey: .answer)
            case .iceCandidate(let candidate):
                try container.encode(PayloadType.iceCandidate, forKey: .type)
                try container.encode(candidate, forKey: .candidate)
            case .helperPing(let ping):
                try container.encode(PayloadType.helperPing, forKey: .type)
                try container.encode(ping, forKey: .helperPing)
            case .helperAck(let ack):
                try container.encode(PayloadType.helperAck, forKey: .type)
                try container.encode(ack, forKey: .helperAck)
            }
        }
    }

    public let sessionID: UUID
    public let timestamp: Date
    public let payload: Payload

    public init(sessionID: UUID, timestamp: Date = Date(), payload: Payload) {
        self.sessionID = sessionID
        self.timestamp = timestamp
        self.payload = payload
    }
}

/// Standard WebRTC session description wrapper.
public struct SessionDescription: Codable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case offer
        case answer
    }

    public let kind: Kind
    public let sdp: String

    public init(kind: Kind, sdp: String) {
        self.kind = kind
        self.sdp = sdp
    }
}

/// ICE candidate payload for network traversal.
public struct IceCandidate: Codable, Sendable {
    public let sdpMid: String
    public let sdpMLineIndex: Int32
    public let candidate: String

    public init(sdpMid: String, sdpMLineIndex: Int32, candidate: String) {
        self.sdpMid = sdpMid
        self.sdpMLineIndex = sdpMLineIndex
        self.candidate = candidate
    }
}

/// Request sent when AI confidence is insufficient and a human helper is needed.
public struct HelperPing: Codable, Sendable {
    public enum Reason: Codable, Sendable {
        case lowConfidence(objectType: String, confidence: Double)
        case manualRequest(context: String)
    }

    public let requestID: UUID
    public let reason: Reason
    public let preferredLanguage: String

    public init(requestID: UUID = UUID(), reason: Reason, preferredLanguage: String = "en-US") {
        self.requestID = requestID
        self.reason = reason
        self.preferredLanguage = preferredLanguage
    }
}

/// Response sent when a helper accepts a request.
public struct HelperAck: Codable, Sendable {
    public let requestID: UUID
    public let helperID: UUID
    public let eta: TimeInterval

    public init(requestID: UUID, helperID: UUID, eta: TimeInterval) {
        self.requestID = requestID
        self.helperID = helperID
        self.eta = eta
    }
}
