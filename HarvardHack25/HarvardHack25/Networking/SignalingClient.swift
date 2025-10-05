import Foundation
#if canImport(SocketIO)
import SocketIO
#endif

@MainActor
public protocol SignalingClientDelegate: AnyObject {
    func signalingClient(_ client: SignalingClient, didReceive envelope: SignalingEnvelope)
    func signalingClientDidConnect(_ client: SignalingClient)
    func signalingClientDidDisconnect(_ client: SignalingClient, reason: String)
    func signalingClient(_ client: SignalingClient, didReceiveError error: Error)
}

@MainActor
public final class SignalingClient {
    public struct Configuration: Sendable {
        public let socketURL: URL
        public let namespace: String
        public let loggingEnabled: Bool

        public init(socketURL: URL, namespace: String = "/", loggingEnabled: Bool = false) {
            self.socketURL = socketURL
            self.namespace = namespace
            self.loggingEnabled = loggingEnabled
        }
    }

#if canImport(SocketIO)
    private let configuration: Configuration
    private weak var delegate: SignalingClientDelegate?
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var sessionID: UUID?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
#else
    private let configuration: Configuration
    private weak var delegate: SignalingClientDelegate?
#endif

    public init(configuration: Configuration, delegate: SignalingClientDelegate?) {
        self.configuration = configuration
        self.delegate = delegate
#if canImport(SocketIO)
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
#endif
    }

    public var isConnected: Bool {
#if canImport(SocketIO)
        socket?.status == .connected
#else
        false
#endif
    }

    public func connect(asVisionPro sessionID: UUID) {
#if canImport(SocketIO)
        guard socket == nil else { return }

        self.sessionID = sessionID

        let manager = SocketManager(
            socketURL: configuration.socketURL,
            config: [
                .log(configuration.loggingEnabled),
                .compress,
                .forceWebsockets(true),
                .reconnects(true),
                .reconnectAttempts(10),
                .reconnectWait(1),
                .reconnectWaitMax(5)
            ]
        )

        let socket: SocketIOClient
        if configuration.namespace == "/" {
            socket = manager.defaultSocket
        } else {
            socket = manager.socket(forNamespace: configuration.namespace)
        }

        self.manager = manager
        self.socket = socket

        registerCoreHandlers(on: socket)
        socket.connect()
#else
        delegate?.signalingClientDidDisconnect(self, reason: "SocketIO framework not linked")
#endif
    }

    public func disconnect() {
#if canImport(SocketIO)
        socket?.disconnect()
        manager?.disconnect()
        manager = nil
        socket = nil
        sessionID = nil
#endif
    }

    public func sendEnvelope(_ envelope: SignalingEnvelope) {
#if canImport(SocketIO)
        guard let socket else {
            delegate?.signalingClient(self, didReceiveError: AppError.invalidState(reason: "Socket not connected"))
            return
        }

        do {
            let payload = try encodeToDictionary(envelope)
            socket.emit("signaling", payload)
        } catch {
            delegate?.signalingClient(self, didReceiveError: error)
        }
#else
        delegate?.signalingClient(self, didReceiveError: AppError.notImplemented(feature: "SocketIO unavailable"))
#endif
    }

    public func sendHelperAck(_ ack: HelperAck) {
#if canImport(SocketIO)
        guard let sessionID else {
            delegate?.signalingClient(self, didReceiveError: AppError.invalidState(reason: "Missing session ID"))
            return
        }
        let envelope = SignalingEnvelope(sessionID: sessionID, payload: .helperAck(ack))
        sendEnvelope(envelope)
#else
        delegate?.signalingClient(self, didReceiveError: AppError.notImplemented(feature: "helper acks without SocketIO"))
#endif
    }

    public func sendHelperPing(_ ping: HelperPing) {
#if canImport(SocketIO)
        guard let sessionID, let socket else {
            delegate?.signalingClient(self, didReceiveError: AppError.invalidState(reason: "Socket not connected"))
            return
        }

        do {
            let payload = try encodeToDictionary([
                "sessionID": sessionID.uuidString,
                "ping": encodeToDictionary(ping)
            ])
            socket.emit("helper-request", payload)
        } catch {
            delegate?.signalingClient(self, didReceiveError: error)
        }
#else
        delegate?.signalingClient(self, didReceiveError: AppError.notImplemented(feature: "helper pings without SocketIO"))
#endif
    }

    public func sendStreamMetadata(_ metadata: StreamMetadata) {
#if canImport(SocketIO)
        guard let sessionID, let socket else { return }
        do {
            let payload = try encodeToDictionary([
                "sessionID": sessionID.uuidString,
                "metadata": encodeToDictionary(metadata)
            ])
            socket.emit("stream-metadata", payload)
        } catch {
            delegate?.signalingClient(self, didReceiveError: error)
        }
#endif
    }

#if canImport(SocketIO)
    private func registerCoreHandlers(on socket: SocketIOClient) {
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self else { return }
            self.delegate?.signalingClientDidConnect(self)
            self.registerVisionPro()
        }

        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            guard let self else { return }
            let reason = data.first as? String ?? "unknown"
            self.delegate?.signalingClientDidDisconnect(self, reason: reason)
        }

        socket.on(clientEvent: .error) { [weak self] data, _ in
            guard let self else { return }
            let error = data.first as? Error ?? AppError.serviceFailure(underlying: SocketError.unknown)
            self.delegate?.signalingClient(self, didReceiveError: error)
        }

        socket.on("signaling") { [weak self] data, _ in
            guard let self else { return }
            self.handleSignalingPayload(data)
        }
    }

    private func registerVisionPro() {
        guard let socket, let sessionID else { return }
        socket.emit("register-vision-pro", ["sessionID": sessionID.uuidString])
    }

    private func handleSignalingPayload(_ data: [Any]) {
        guard let raw = data.first else { return }

        do {
            if let dict = raw as? [String: Any] {
                let envelope: SignalingEnvelope = try decodeFromDictionary(dict)
                delegate?.signalingClient(self, didReceive: envelope)
            } else if let str = raw as? String, let payload = str.data(using: .utf8) {
                let envelope = try decoder.decode(SignalingEnvelope.self, from: payload)
                delegate?.signalingClient(self, didReceive: envelope)
            }
        } catch {
            delegate?.signalingClient(self, didReceiveError: error)
        }
    }

    private func encodeToDictionary<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try encoder.encode(value)
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AppError.serviceFailure(underlying: SocketError.encodingFailed)
        }
        return obj
    }

    private func decodeFromDictionary<T: Decodable>(_ dict: [String: Any]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: dict)
        return try decoder.decode(T.self, from: data)
    }
#endif
}

public enum SocketError: Error {
    case unknown
    case encodingFailed
}
