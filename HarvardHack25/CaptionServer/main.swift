import Foundation
import Network

// MARK: - Simple in-memory store of the last upload
var lastJPEG: Data?
var lastPrompt: String = "(none)"
var lastBytes: Int = 0
var lastSavedURL: URL?

let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
let desktopFile = desktop.appendingPathComponent("last_roi.jpg")

// MARK: - Start listener
let port: NWEndpoint.Port = 8080
let listener = try NWListener(using: .tcp, on: port)
print("CaptionServer listening on http://127.0.0.1:\(port)")

listener.newConnectionHandler = { conn in
    conn.start(queue: .global())
    handleConnection(conn)
}
listener.start(queue: .global())
RunLoop.main.run()

// MARK: - HTTP handling

func handleConnection(_ conn: NWConnection) {
    readHeadersAndOverflow(on: conn) { headerData, overflow in
        guard let headerData,
              let header = String(data: headerData, encoding: .utf8),
              let requestLine = header.components(separatedBy: "\r\n").first else {
            conn.cancel(); return
        }

        let parts = requestLine.split(separator: " ")
        let method = parts.first.map(String.init) ?? "GET"
        let path   = parts.dropFirst().first.map(String.init) ?? "/"

        // If client asked for 100-continue, be polite
        if (parseHeader(header, key: "Expect")?.lowercased() == "100-continue") {
            let interim = "HTTP/1.1 100 Continue\r\n\r\n".data(using: .utf8)!
            conn.send(content: interim, completion: .contentProcessed { _ in })
        }

        if method == "POST", path == "/caption" {
            // Prefer to read until close (works with Connection: close)
            let contentLength = parseContentLength(header)
            readBody(on: conn, overflow: overflow, contentLength: contentLength) { body in
                guard let body else { sendHTTP400(conn, "Bad Request"); return }

                lastJPEG = body
                lastBytes = body.count
                lastPrompt = parseHeader(header, key: "X-Prompt") ?? "(none)"
                try? body.write(to: desktopFile)
                lastSavedURL = desktopFile

                print("POST /caption  \(body.count) bytes  prompt=\"\(lastPrompt)\" saved=\(desktopFile.path)")

                // Return a deterministic caption for testing
                let caption = "Frothy beer in a glass."
                sendHTTP200Text(conn, caption)
            }
        } else if method == "GET", path == "/" {
            sendIndexHTML(conn)
        } else if method == "GET", path == "/last.jpg" {
            if let img = lastJPEG { sendHTTP200JPEG(conn, img) }
            else { sendHTTP404(conn, "No image uploaded yet.") }
        } else {
            sendHTTP404(conn, "Not found")
        }
    }
}

// Reads headers + returns (headers, overflowAfterHeaders)
func readHeadersAndOverflow(on conn: NWConnection, _ cb: @escaping (Data?, Data?) -> Void) {
    var buffer = Data()
    func loop() {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { data, _, isComplete, error in
            if let d = data { buffer.append(d) }
            if let range = buffer.range(of: Data("\r\n\r\n".utf8)) {
                let headerEnd = range.upperBound
                let headers = buffer.subdata(in: 0..<headerEnd)
                let overflow = (headerEnd < buffer.count) ? buffer.subdata(in: headerEnd..<buffer.count) : nil
                cb(headers, overflow)
                return
            }
            if isComplete || error != nil { cb(nil, nil); return }
            loop()
        }
    }
    loop()
}

func parseContentLength(_ header: String) -> Int? {
    parseHeader(header, key: "Content-Length").flatMap(Int.init)
}

func parseHeader(_ header: String, key: String) -> String? {
    for line in header.split(separator: "\r\n") {
        let lower = line.lowercased()
        if lower.hasPrefix(key.lowercased() + ":") {
            return line.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces)
        }
    }
    return nil
}

/// Reads the request body.
/// If Content-Length is present, reads exactly that many bytes (including any overflow).
/// Otherwise, reads until the connection closes.
func readBody(on conn: NWConnection, overflow: Data?, contentLength: Int?, _ cb: @escaping (Data?) -> Void) {
    // If we have a length, honor it (simple & fast)
    if let len = contentLength {
        let already = overflow?.count ?? 0
        let remaining = max(0, len - already)
        readExactBytes(on: conn, count: remaining) { rest in
            guard let rest else { cb(nil); return }
            var body = Data(capacity: len)
            if let overflow { body.append(overflow) }
            body.append(rest)
            cb(body)
        }
        return
    }

    // Otherwise read until close (Connection: close)
    var body = Data()
    if let overflow { body.append(overflow) }
    func loop() {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { data, _, isComplete, error in
            if let d = data { body.append(d) }
            if isComplete || error != nil {
                cb(body.isEmpty ? nil : body)
                return
            }
            loop()
        }
    }
    loop()
}

func readExactBytes(on conn: NWConnection, count: Int, _ cb: @escaping (Data?) -> Void) {
    guard count > 0 else { cb(Data()); return }
    var remaining = count
    var out = Data(capacity: count)
    func loop() {
        guard remaining > 0 else { cb(out); return }
        let chunk = min(remaining, 64 * 1024)
        conn.receive(minimumIncompleteLength: 1, maximumLength: chunk) { data, _, isComplete, error in
            if let d = data { out.append(d); remaining -= d.count }
            if isComplete || error != nil { cb(remaining == 0 ? out : nil); return }
            loop()
        }
    }
    loop()
}

// -------- Responses
func sendHTTP200Text(_ conn: NWConnection, _ text: String) {
    let body = Data(text.utf8)
    let resp = """
    HTTP/1.1 200 OK\r
    Content-Type: text/plain; charset=utf-8\r
    Content-Length: \(body.count)\r
    Connection: close\r
    \r

    """.data(using: .utf8)! + body
    conn.send(content: resp, completion: .contentProcessed { _ in conn.cancel() })
}

func sendHTTP200JPEG(_ conn: NWConnection, _ data: Data) {
    var headers = """
    HTTP/1.1 200 OK\r
    Content-Type: image/jpeg\r
    Content-Length: \(data.count)\r
    Connection: close\r
    \r

    """.data(using: .utf8)!
    headers.append(data)
    conn.send(content: headers, completion: .contentProcessed { _ in conn.cancel() })
}

func sendHTTP404(_ conn: NWConnection, _ msg: String) {
    let body = Data(msg.utf8)
    let resp = """
    HTTP/1.1 404 Not Found\r
    Content-Type: text/plain; charset=utf-8\r
    Content-Length: \(body.count)\r
    Connection: close\r
    \r

    """.data(using: .utf8)! + body
    conn.send(content: resp, completion: .contentProcessed { _ in conn.cancel() })
}

func sendHTTP400(_ conn: NWConnection, _ msg: String) {
    let body = Data(msg.utf8)
    let resp = """
    HTTP/1.1 400 Bad Request\r
    Content-Type: text/plain; charset=utf-8\r
    Content-Length: \(body.count)\r
    Connection: close\r
    \r

    """.data(using: .utf8)! + body
    conn.send(content: resp, completion: .contentProcessed { _ in conn.cancel() })
}

func sendIndexHTML(_ conn: NWConnection) {
    let savedPath = lastSavedURL?.path ?? "(none)"
    let imgTag = (lastJPEG != nil)
        ? "<img src=\"/last.jpg\" alt=\"last roi\" />"
        : "<em>No image uploaded yet.</em>"

    let html = """
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8"/>
      <title>CaptionServer Status</title>
      <style>
        body { font: 14px -apple-system, BlinkMacSystemFont, sans-serif; margin: 24px; }
        img { max-width: 320px; image-rendering: -webkit-optimize-contrast; }
        .row { margin-bottom: 12px; }
        code { background: #f5f5f7; padding: 2px 4px; border-radius: 4px; }
      </style>
    </head>
    <body>
      <h2>CaptionServer — Latest Upload</h2>
      <div class="row">Bytes: <code>\(lastBytes)</code></div>
      <div class="row">Prompt: <code>\(escapeHTML(lastPrompt))</code></div>
      <div class="row">Saved to: <code>\(escapeHTML(savedPath))</code></div>
      <div class="row">
        \(imgTag)
      </div>
      <hr/>
      <div>POST endpoint: <code>/caption</code></div>
    </body>
    </html>
    """
    let body = Data(html.utf8)
    let resp = """
    HTTP/1.1 200 OK\r
    Content-Type: text/html; charset=utf-8\r
    Content-Length: \(body.count)\r
    Connection: close\r
    \r

    """.data(using: .utf8)! + body
    conn.send(content: resp, completion: .contentProcessed { _ in conn.cancel() })
}

func escapeHTML(_ s: String) -> String {
    s.replacingOccurrences(of: "&", with: "&amp;")
     .replacingOccurrences(of: "<", with: "&lt;")
     .replacingOccurrences(of: ">", with: "&gt;")
}

