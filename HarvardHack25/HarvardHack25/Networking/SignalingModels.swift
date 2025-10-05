import Foundation

public struct SignalingEnvelope: Codable, Sendable {
    public let sessionID: UUID
    public let timestamp: Date
    public let payload: SignalingPayload

    public init(sessionID: UUID, timestamp: Date = Date(), payload: SignalingPayload) {
        self.sessionID = sessionID
        self.timestamp = timestamp
        self.payload = payload
    }
}

public enum SignalingPayload: Codable, Sendable {
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
            let value = try container.decode(SessionDescription.self, forKey: .offer)
            self = .offer(value)
        case .answer:
            let value = try container.decode(SessionDescription.self, forKey: .answer)
            self = .answer(value)
        case .iceCandidate:
            let value = try container.decode(IceCandidate.self, forKey: .candidate)
            self = .iceCandidate(value)
        case .helperPing:
            let value = try container.decode(HelperPing.self, forKey: .helperPing)
            self = .helperPing(value)
        case .helperAck:
            let value = try container.decode(HelperAck.self, forKey: .helperAck)
            self = .helperAck(value)
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

public struct HelperAck: Codable, Sendable {
    public let requestID: UUID
    public let helperID: UUID
    public let etaSeconds: Int

    public init(requestID: UUID, helperID: UUID, etaSeconds: Int) {
        self.requestID = requestID
        self.helperID = helperID
        self.etaSeconds = etaSeconds
    }

    private enum CodingKeys: String, CodingKey {
        case requestID
        case helperID
        case etaSeconds = "eta"
    }
}

public struct StreamMetadata: Codable, Sendable {
    public enum Quality: String, Codable, Sendable {
        case low
        case medium
        case high
    }

    public let timestamp: Date
    public let quality: Quality
    public let latencyMs: Double
    public let bitrateBps: Double

    public init(timestamp: Date = Date(), quality: Quality, latencyMs: Double, bitrateBps: Double) {
        self.timestamp = timestamp
        self.quality = quality
        self.latencyMs = latencyMs
        self.bitrateBps = bitrateBps
    }

    private enum CodingKeys: String, CodingKey {
        case timestamp
        case quality
        case latencyMs = "latency"
        case bitrateBps = "bitrate"
    }
}
