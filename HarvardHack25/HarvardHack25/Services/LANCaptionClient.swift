import Foundation

struct LANCaptionClient {
    // Simulator: loopback to your Mac
    #if targetEnvironment(simulator)
    let endpoint  = URL(string: "http://127.0.0.1:8080/caption")!
    let statusURL = URL(string: "http://127.0.0.1:8080/")!
    #else
    private static func host() -> String {
        if let h = ProcessInfo.processInfo.environment["VLM_HOST"], !h.isEmpty { return h }
        return "192.168.0.123" // change when you move to another laptop
    }
    let endpoint  = URL(string: "http://\(host()):8080/caption")!
    let statusURL = URL(string: "http://\(host()):8080/")!
    #endif

    // Generous while testing; tighten later if you want
    let firstByteDeadlineMs: Int = 3000
    let retryDeadlineMs: Int     = 5000

    var endpointString: String { endpoint.absoluteString }

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

    /// Simple, reliable POST: set httpBody and read until close on the server side.
    func caption(jpeg: Data, prompt: String, timeoutMs: Int) async throws -> String {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        req.setValue(prompt, forHTTPHeaderField: "X-Prompt")

        // Keep the handshake simple for our tiny server
        req.setValue("", forHTTPHeaderField: "Expect")          // disable 100-continue
        req.setValue("close", forHTTPHeaderField: "Connection")  // server will read until close

        // Explicit Content-Length (some servers are picky; URLSession would set it anyway)
        req.setValue(String(jpeg.count), forHTTPHeaderField: "Content-Length")
        req.httpBody = jpeg

        req.timeoutInterval = TimeInterval(timeoutMs) / 1000.0

        let (data, _) = try await URLSession.shared.data(for: req)
        return String(data: data, encoding: .utf8) ?? ""
    }
}

