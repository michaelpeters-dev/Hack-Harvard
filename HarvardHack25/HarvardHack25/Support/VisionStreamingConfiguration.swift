import Foundation
#if canImport(WebRTC)
import WebRTC
#endif

/// Resolves runtime configuration for the Vision Pro livestream stack.
///
/// Order of precedence for each property:
/// 1. Environment variables (for local overrides / CI)
/// 2. Info.plist entries (Bundle settings for production builds)
/// 3. Hard-coded defaults (safe localhost dev values)
struct VisionStreamingConfiguration {
    struct Socket {
        let url: URL
        let namespace: String
        let loggingEnabled: Bool
    }

#if canImport(WebRTC)
    struct ICE {
        let servers: [RTCIceServer]
    }
#endif

    let socket: Socket
#if canImport(WebRTC)
    let ice: ICE
#endif

    static func load() -> VisionStreamingConfiguration {
        let socketURL = Self.resolveSocketURL()
        let namespace = Self.resolveString(env: "VISION_SOCKET_NAMESPACE",
                                           plist: "VisionSocketNamespace",
                                           defaultValue: "/")
        let logging = Self.resolveBool(env: "VISION_SOCKET_LOGGING",
                                       plist: "VisionSocketLoggingEnabled",
                                       defaultValue: false)
        let socket = Socket(url: socketURL, namespace: namespace, loggingEnabled: logging)

#if canImport(WebRTC)
        let iceServers = Self.resolveICEServers()
        let ice = ICE(servers: iceServers)
        return VisionStreamingConfiguration(socket: socket, ice: ice)
#else
        return VisionStreamingConfiguration(socket: socket)
#endif
    }
}

private extension VisionStreamingConfiguration {
    static func resolveSocketURL() -> URL {
        if let env = ProcessInfo.processInfo.environment["VISION_SOCKET_URL"],
           let url = URL(string: env) {
            return url
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "VisionSocketURL") as? String,
           let url = URL(string: plist) {
            return url
        }
        return URL(string: "http://localhost:3001")!
    }

    static func resolveString(env: String, plist: String, defaultValue: String) -> String {
        if let envValue = ProcessInfo.processInfo.environment[env], envValue.isEmpty == false {
            return envValue
        }
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: plist) as? String,
           plistValue.isEmpty == false {
            return plistValue
        }
        return defaultValue
    }

    static func resolveBool(env: String, plist: String, defaultValue: Bool) -> Bool {
        if let envValue = ProcessInfo.processInfo.environment[env]?.lowercased() {
            switch envValue {
            case "1", "true", "yes": return true
            case "0", "false", "no": return false
            default: break
            }
        }
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: plist) as? NSNumber {
            return plistValue.boolValue
        }
        return defaultValue
    }
}

#if canImport(WebRTC)
private extension VisionStreamingConfiguration {
    static func resolveICEServers() -> [RTCIceServer] {
        let stunList = resolveList(env: "VISION_STUN_SERVERS",
                                   plist: "VisionStunServers",
                                   defaultValue: ["stun:stun.l.google.com:19302",
                                                  "stun:stun1.l.google.com:19302"])
        var servers: [RTCIceServer] = stunList.map { RTCIceServer(urlStrings: [$0]) }

        if let turnDicts = resolveTurnDictionaries() {
            servers.append(contentsOf: turnDicts)
        }
        return servers
    }

    static func resolveList(env: String, plist: String, defaultValue: [String]) -> [String] {
        if let envValue = ProcessInfo.processInfo.environment[env], envValue.isEmpty == false {
            return envValue.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: plist) as? [String], plistValue.isEmpty == false {
            return plistValue
        }
        return defaultValue
    }

    static func resolveTurnDictionaries() -> [RTCIceServer]? {
        if let envJSON = ProcessInfo.processInfo.environment["VISION_TURN_SERVERS"],
           let data = envJSON.data(using: .utf8),
           let objects = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return objects.compactMap(iceServer(from:))
        }

        if let plistValue = Bundle.main.object(forInfoDictionaryKey: "VisionTurnServers") as? [[String: Any]] {
            return plistValue.compactMap(iceServer(from:))
        }
        return nil
    }

    static func iceServer(from dictionary: [String: Any]) -> RTCIceServer? {
        guard let urlStrings = dictionary["urls"] as? [String] ??
                (dictionary["url"] as? String).map({ [$0] }),
              urlStrings.isEmpty == false else {
            return nil
        }
        let username = dictionary["username"] as? String
        let credential = dictionary["credential"] as? String
        return RTCIceServer(urlStrings: urlStrings, username: username, credential: credential)
    }
}
#endif
