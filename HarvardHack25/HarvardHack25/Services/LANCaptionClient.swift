import Foundation

struct LANCaptionClient {
    // --- Config resolution ---
    private static func resolvedHost() -> String {
        if let env = ProcessInfo.processInfo.environment["VLM_HOST"], !env.isEmpty {
            return env
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "VLMHost") as? String, !plist.isEmpty {
            return plist
        }
        return "Michaels-MacBook-Pro-6.local" // default
    }

    private static func resolvedPort() -> Int {
        if let env = ProcessInfo.processInfo.environment["VLM_PORT"], let p = Int(env) {
            return p
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "VLMPort") as? NSNumber {
            return plist.intValue
        }
        return 8080
    }

    private static var baseURL: URL {
        URL(string: "http://\(resolvedHost()):\(resolvedPort())")!
    }

    // --- Endpoints ---
    let endpoint  = baseURL.appendingPathComponent("caption")
    let statusURL = baseURL

    // --- Timeouts ---
    let firstByteDeadlineMs: Int = 3000
    let retryDeadlineMs: Int     = 5000

    var endpointString: String { endpoint.absoluteString }

    // Health check GET /
    func ping() async -> String {
        var req = URLRequest(url: statusURL)
        req.httpMethod = "GET"
        req.setValue("close", forHTTPHeaderField: "Connection")
        req.timeoutInterval = TimeInterval(firstByteDeadlineMs) / 1000.0
        do {
            _ = try await URLSession.shared.data(for: req)
            return "OK"
        } catch {
            return "Ping failed: \(error.localizedDescription)"
        }
    }

    // POST /caption  (raw JPEG bytes + X-Prompt)
    func caption(jpeg: Data, prompt: String, timeoutMs: Int) async throws -> String {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        req.setValue(prompt, forHTTPHeaderField: "X-Prompt")
        req.setValue("", forHTTPHeaderField: "Expect")          // disable 100-continue
        req.setValue("close", forHTTPHeaderField: "Connection") // server will read until close
        req.setValue(String(jpeg.count), forHTTPHeaderField: "Content-Length")
        req.httpBody = jpeg
        req.timeoutInterval = TimeInterval(timeoutMs) / 1000.0

        let (data, _) = try await URLSession.shared.data(for: req)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
