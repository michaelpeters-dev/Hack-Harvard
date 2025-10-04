import Foundation
import Network

// MARK: - Simple in-memory store of the last upload
var lastJPEG: Data?
var lastPrompt: String = "(none)"
var lastBytes: Int = 0
var lastSavedURL: URL?

// Also write to Desktop for easy manual inspection
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
    readUntilDoubleCRLF(on: conn) { headerData in
        guard let headerData,
              let header = String(data: headerData, encoding: .utf8),
              let requestLine = header.components(separatedBy: "\r\n").first
        else { conn.cancel(); return }

        let parts = requestLine.split(separator: " ")
        let method = parts.first.map(String.init) ?? "GET"
        let path   = parts.dropFirst().first.map(String.init) ?? "/"

        if method == "POST", path == "/caption" {
            let contentLength = parseContentLength(header) ?? 0
            readExactBytes(on: conn, count: contentLength) { body in
                guard let body else { sendHTTP400(conn, "Bad Request"); return }
                lastJPEG = body
                lastBytes = body.count
                lastPrompt = parseHeader(header, key: "X-Prompt") ?? "(none)"
                // Save to Desktop for convenience
                try? body.write(to: desktopFile)
                lastSavedURL = desktopFile
                print("POST /caption  \(body.count) bytes  prompt=\"\(lastPrompt)\"  saved=\(desktopFile.path)")

                let caption = "Frothy beer in a glass." // test caption
                sendHTTP200Text(conn, caption)
            }
        } else if method == "GET", path == "/" {
            sendIndexHTML(conn)
        } else if method == "GET", path == "/last.jpg" {
            if let img = lastJPEG {
                sendHTTP200JPEG(conn, img)
            } else {
                sendHTTP404(conn, "No image uploaded yet.")
            }
        } else {
            sendHTTP404(conn, "Not found")
        }
    }
}

func readUntilDoubleCRLF(on conn: NWConnection, _ cb: @escaping (Data?) -> Void) {
    var buffer = Data()
    func loop() {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, isComplete, error in
            if let d = data { buffer.append(d) }
            if buffer.range(of: Data("\r\n\r\n".utf8)) != nil { cb(buffer); return }
            if isComplete || error != nil { cb(nil); return }
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

func readExactBytes(on conn: NWConnection, count: Int, _ cb: @escaping (Data?) -> Void) {
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
