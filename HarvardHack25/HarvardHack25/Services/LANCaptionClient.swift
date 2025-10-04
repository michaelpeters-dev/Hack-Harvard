import Foundation

struct LANCaptionClient {
    #if targetEnvironment(simulator)
    private let endpoint = URL(string: "http://127.0.0.1:8080/caption")!
    #else
    private let endpoint = URL(string: "http://192.168.0.123:8080/caption")! // set via env var later
    #endif

    let firstByteDeadlineMs: Int = 1000

    func caption(jpeg: Data, prompt: String) async -> String? {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        req.setValue(prompt, forHTTPHeaderField: "X-Prompt")
        req.timeoutInterval = TimeInterval(firstByteDeadlineMs) / 1000.0
        do {
            let (data, _) = try await URLSession.shared.upload(for: req, from: jpeg)
            return String(data: data, encoding: .utf8)
        } catch { return nil }
    }
}

