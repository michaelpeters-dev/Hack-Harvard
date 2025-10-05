import Foundation
#if canImport(WebRTC)
import WebRTC

@MainActor
public protocol VisionRTCSessionDelegate: AnyObject {
    func rtcSession(_ session: VisionRTCSession, didProduce envelope: SignalingEnvelope)
    func rtcSession(_ session: VisionRTCSession, didUpdate connectionState: RTCPeerConnectionState)
    func rtcSession(_ session: VisionRTCSession, didEmit metadata: StreamMetadata)
    func rtcSession(_ session: VisionRTCSession, didFail error: Error)
}

@MainActor
public final class VisionRTCSession: NSObject {
    public struct Configuration {
        public let iceServers: [RTCIceServer]
        public let maxBitrateBps: Int?
        public let statsInterval: TimeInterval

        public init(iceServers: [RTCIceServer], maxBitrateBps: Int? = nil, statsInterval: TimeInterval = 2.0) {
            self.iceServers = iceServers
            self.maxBitrateBps = maxBitrateBps
            self.statsInterval = statsInterval
        }
    }

    private let configuration: Configuration
    private weak var delegate: VisionRTCSessionDelegate?

    private let peerFactory: RTCPeerConnectionFactory
    private var peerConnection: RTCPeerConnection?
    private var videoSource: RTCVideoSource?
    private var videoTrack: RTCVideoTrack?
    private var dataChannel: RTCDataChannel?
    private var statsTimer: Timer?
    private var sessionID: UUID?
    private var lastBytesSent: Double?

    public init(configuration: Configuration, delegate: VisionRTCSessionDelegate?) {
        self.configuration = configuration
        self.delegate = delegate

        RTCInitializeSSL()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        self.peerFactory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
        super.init()
    }

    deinit {
        statsTimer?.invalidate()
        RTCCleanupSSL()
    }

    public func prepare(sessionID: UUID) {
        self.sessionID = sessionID
        buildPeerConnection()
    }

    public func makeLocalVideoSource() -> RTCVideoSource? {
        ensureLocalVideoTrack()
        return videoSource
    }

    public func attachCapturer(_ capturer: RTCVideoCapturer) {
        _ = capturer
        ensureLocalVideoTrack()
    }

    public func offer() async throws -> SessionDescription {
        guard let peerConnection else {
            throw AppError.invalidState(reason: "Peer not ready")
        }

        let constraints = RTCMediaConstraints(mandatoryConstraints: [
            "OfferToReceiveAudio": kRTCMediaConstraintsValueFalse,
            "OfferToReceiveVideo": kRTCMediaConstraintsValueFalse
        ], optionalConstraints: nil)

        return try await withCheckedThrowingContinuation { continuation in
            peerConnection.offer(for: constraints) { [weak self] sdp, error in
                guard let self else { return }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sdp else {
                    continuation.resume(throwing: AppError.invalidState(reason: "Missing SDP"))
                    return
                }

                peerConnection.setLocalDescription(sdp) { error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let description = SessionDescription(kind: .offer, sdp: sdp.sdp)
                    continuation.resume(returning: description)
                }
            }
        }
    }

    public func apply(_ description: SessionDescription) async throws {
        guard let peerConnection else {
            throw AppError.invalidState(reason: "Peer not ready")
        }

        let rtcType: RTCSdpType = description.kind == .offer ? .offer : .answer
        let rtcDescription = RTCSessionDescription(type: rtcType, sdp: description.sdp)

        try await withCheckedThrowingContinuation { continuation in
            peerConnection.setRemoteDescription(rtcDescription) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func addIceCandidate(_ candidate: IceCandidate) {
        guard let peerConnection else { return }
        let rtcCandidate = RTCIceCandidate(
            sdp: candidate.candidate,
            sdpMLineIndex: Int32(candidate.sdpMLineIndex),
            sdpMid: candidate.sdpMid
        )
        peerConnection.add(rtcCandidate)
    }

    public func updateBitrate(_ bitrate: Int) {
        guard let sender = peerConnection?.senders.first(where: { $0.track == videoTrack }) else { return }
        let parameters = sender.parameters
        if parameters.encodings.isEmpty {
            let encoding = RTCRtpEncodingParameters()
            encoding.maxBitrateBps = NSNumber(value: bitrate)
            encoding.minBitrateBps = NSNumber(value: bitrate / 2)
            sender.parameters.encodings = [encoding]
        } else {
            parameters.encodings.forEach { $0.maxBitrateBps = NSNumber(value: bitrate) }
        }
        sender.parameters = parameters
    }

    public func stop() {
        statsTimer?.invalidate()
        statsTimer = nil

        dataChannel?.close()
        dataChannel = nil

        videoTrack?.isEnabled = false
        videoTrack = nil
        videoSource = nil

        peerConnection?.close()
        peerConnection = nil
        lastBytesSent = nil
    }

    public func handleEnvelope(_ envelope: SignalingEnvelope) {
        guard envelope.sessionID == sessionID else { return }

        switch envelope.payload {
        case .answer(let answer):
            Task { try? await apply(answer) }
        case .iceCandidate(let candidate):
            addIceCandidate(candidate)
        case .helperAck:
            break
        case .offer, .helperPing:
            break
        }
    }

    @discardableResult
    private func ensureLocalVideoTrack() -> RTCVideoTrack? {
        if videoSource == nil {
            videoSource = peerFactory.videoSource()
        }

        if videoTrack == nil, let videoSource {
            videoTrack = peerFactory.videoTrack(with: videoSource, trackId: "vision-pro-camera")
        }

        if let videoTrack, peerConnection?.senders.contains(where: { $0.track == videoTrack }) == false {
            let stream = peerFactory.mediaStream(withStreamId: "vision-pro-stream")
            stream.addVideoTrack(videoTrack)
            peerConnection?.add(stream)
        }

        return videoTrack
    }

    private func buildPeerConnection() {
        let config = RTCConfiguration()
        config.iceServers = configuration.iceServers
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: [
            "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue
        ])

        let peerConnection = peerFactory.peerConnection(with: config, constraints: constraints, delegate: self)
        self.peerConnection = peerConnection

        let dataChannelConfig = RTCDataChannelConfiguration()
        dataChannelConfig.isOrdered = true
        dataChannelConfig.isNegotiated = false
        dataChannel = peerConnection.dataChannel(forLabel: "metadata", configuration: dataChannelConfig)
        dataChannel?.delegate = self

        startStatsTimer()
    }

    private func startStatsTimer() {
        statsTimer?.invalidate()
        statsTimer = Timer.scheduledTimer(withTimeInterval: configuration.statsInterval, repeats: true) { [weak self] _ in
            self?.collectStats()
        }
    }

    private func collectStats() {
        guard let peerConnection else { return }
        peerConnection.statistics { [weak self] reports in
            guard let self else { return }
            let (bytesSent, latency) = self.parseStats(reports)
            let deltaBytes: Double
            if let lastBytes = self.lastBytesSent {
                deltaBytes = max(0, bytesSent - lastBytes)
            } else {
                deltaBytes = 0
            }
            self.lastBytesSent = bytesSent

            let bitrate = deltaBytes * 8 / self.configuration.statsInterval
            let quality = self.quality(for: bitrate)
            let metadata = StreamMetadata(
                quality: quality,
                latencyMs: latency,
                bitrateBps: bitrate
            )
            self.delegate?.rtcSession(self, didEmit: metadata)
        }
    }

    private func parseStats(_ reports: [RTCStatisticsReport]) -> (Double, Double) {
        var bytesSent: Double = 0
        var currentRoundTrip: Double = 0

        for report in reports {
            if report.type == "outbound-rtp", let bytes = report.values["bytesSent"] as? Double {
                bytesSent = max(bytesSent, bytes)
            }
            if report.type == "candidate-pair", let rtt = report.values["currentRoundTripTime"] as? Double {
                currentRoundTrip = max(currentRoundTrip, rtt)
            }
        }

        let latencyMs = currentRoundTrip * 1000
        return (bytesSent, latencyMs)
    }

    private func quality(for bitrate: Double) -> StreamMetadata.Quality {
        switch bitrate {
        case ..<500_000:
            return .low
        case ..<2_000_000:
            return .medium
        default:
            return .high
        }
    }
}

extension VisionRTCSession: RTCPeerConnectionDelegate {
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}

    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        guard let sessionID else { return }
        let model = IceCandidate(
            sdpMid: candidate.sdpMid ?? "",
            sdpMLineIndex: candidate.sdpMLineIndex,
            candidate: candidate.sdp
        )
        let envelope = SignalingEnvelope(sessionID: sessionID, payload: .iceCandidate(model))
        delegate?.rtcSession(self, didProduce: envelope)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}

    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        dataChannel.delegate = self
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        delegate?.rtcSession(self, didUpdate: newState)
    }
}

extension VisionRTCSession: RTCDataChannelDelegate {
    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {}

    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        guard let json = String(data: buffer.data, encoding: .utf8),
              let data = json.data(using: .utf8),
              let metadata = try? JSONDecoder().decode(StreamMetadata.self, from: data)
        else { return }
        delegate?.rtcSession(self, didEmit: metadata)
    }
}

#else

@MainActor
public protocol VisionRTCSessionDelegate: AnyObject {
    func rtcSession(_ session: VisionRTCSession, didProduce envelope: SignalingEnvelope)
    func rtcSession(_ session: VisionRTCSession, didUpdate connectionState: Any)
    func rtcSession(_ session: VisionRTCSession, didEmit metadata: StreamMetadata)
    func rtcSession(_ session: VisionRTCSession, didFail error: Error)
}

@MainActor
public final class VisionRTCSession {
    public struct Configuration {
        public init(iceServers: [Any], maxBitrateBps: Int? = nil, statsInterval: TimeInterval = 2.0) {}
    }

    public init(configuration: Configuration, delegate: VisionRTCSessionDelegate?) {}

    public func prepare(sessionID: UUID) {}

    public func attachCapturer(_ capturer: Any) {}

    public func offer() async throws -> SessionDescription {
        throw AppError.notImplemented(feature: "WebRTC framework not linked")
    }

    public func apply(_ description: SessionDescription) async throws {
        throw AppError.notImplemented(feature: "WebRTC framework not linked")
    }

    public func addIceCandidate(_ candidate: IceCandidate) {}

    public func updateBitrate(_ bitrate: Int) {}

    public func stop() {}

    public func handleEnvelope(_ envelope: SignalingEnvelope) {}
}

#endif
