# Integration Guide: Vision Pro ↔ Web Helper

This guide explains how to integrate the Web Helper application with the existing Vision Pro app.

## Overview

The web helper receives video streams from the Vision Pro device via WebRTC and allows remote helpers to assist users. The communication flow is:

```
Vision Pro App ←→ Socket.IO Server ←→ Web Helper App
     (Swift)         (Node.js)           (Next.js)
```

## Step 1: Complete Vision Pro WebRTC Implementation

### Update `VisionStreamingService.swift`

Replace the TODO comments with actual WebRTC implementation:

```swift
import Foundation
import Combine
import WebRTC

@MainActor
final class VisionStreamingService: ObservableObject, StreamingSessionManaging {
    @Published private(set) var isStreaming = false
    
    private let helperConnectionService: HelperConnectionService
    private var currentSessionID: UUID?
    private var peerConnection: RTCPeerConnection?
    private var localVideoTrack: RTCVideoTrack?
    
    // Socket.IO client for signaling
    private var socketManager: SocketManager?
    private var socket: SocketIOClient?
    
    init(helperConnectionService: HelperConnectionService) {
        self.helperConnectionService = helperConnectionService
        setupWebRTC()
    }
    
    private func setupWebRTC() {
        // Initialize WebRTC factory
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
            RTCIceServer(urlStrings: ["stun:stun1.l.google.com:19302"])
        ]
        // Add TURN servers for production
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
        )
        
        // Create peer connection (implementation details omitted for brevity)
    }
    
    func configureSession() async throws {
        guard currentSessionID == nil else { return }
        currentSessionID = UUID()
        
        // Connect to Socket.IO signaling server
        let socketURL = URL(string: "YOUR_SOCKET_SERVER_URL")!
        socketManager = SocketManager(socketURL: socketURL, config: [.log(true)])
        socket = socketManager?.defaultSocket
        
        setupSocketListeners()
        socket?.connect()
    }
    
    private func setupSocketListeners() {
        socket?.on("connect") { [weak self] data, ack in
            guard let self = self, let sessionID = self.currentSessionID else { return }
            
            // Register as Vision Pro device
            self.socket?.emit("register-vision-pro", ["sessionID": sessionID.uuidString])
        }
        
        socket?.on("signaling") { [weak self] data, ack in
            guard let self = self,
                  let dict = data[0] as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                  let envelope = try? JSONDecoder().decode(SignalingEnvelope.self, from: jsonData)
            else { return }
            
            Task { await self.handleSignaling(envelope) }
        }
    }
    
    func startStreaming() async throws {
        guard isStreaming == false else { return }
        guard currentSessionID != nil else {
            throw AppError.invalidState(reason: "Streaming requested before session configured")
        }
        
        // Create and send WebRTC offer
        let offer = try await peerConnection?.offer(for: RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: nil
        ))
        
        try await peerConnection?.setLocalDescription(offer!)
        
        // Send offer via Socket.IO
        let sessionDesc = SessionDescription(kind: .offer, sdp: offer!.sdp)
        let envelope = SignalingEnvelope(
            sessionID: currentSessionID!,
            payload: .offer(sessionDesc)
        )
        
        sendSignaling(envelope)
        isStreaming = true
    }
    
    private func sendSignaling(_ envelope: SignalingEnvelope) {
        guard let data = try? JSONEncoder().encode(envelope),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }
        
        socket?.emit("signaling", dict)
    }
    
    private func handleSignaling(_ envelope: SignalingEnvelope) async {
        switch envelope.payload {
        case .answer(let answer):
            let rtcAnswer = RTCSessionDescription(
                type: .answer,
                sdp: answer.sdp
            )
            try? await peerConnection?.setRemoteDescription(rtcAnswer)
            
        case .iceCandidate(let candidate):
            let rtcCandidate = RTCIceCandidate(
                sdp: candidate.candidate,
                sdpMLineIndex: candidate.sdpMLineIndex,
                sdpMid: candidate.sdpMid
            )
            try? await peerConnection?.add(rtcCandidate)
            
        default:
            break
        }
    }
    
    func stopStreaming() async {
        guard isStreaming else { return }
        isStreaming = false
        peerConnection?.close()
        socket?.disconnect()
    }
    
    func updateBitrate(_ bitrate: Int) async {
        guard isStreaming else { return }
        // Apply bitrate constraints to video encoder
    }
}
```

## Step 2: Add WebRTC Dependencies

### Update `Package.swift` or use CocoaPods

Add WebRTC to your Vision Pro project:

**Option A: Swift Package Manager**
```swift
dependencies: [
    .package(url: "https://github.com/webrtc-sdk/Specs", from: "114.0.0")
]
```

**Option B: CocoaPods**
```ruby
pod 'GoogleWebRTC'
```

## Step 3: Capture and Stream Video

### Create Video Capture Service

```swift
import ARKit
import WebRTC

class VideoCaptureService {
    private var videoCapturer: RTCVideoCapturer?
    private var videoSource: RTCVideoSource?
    
    func startCapture(arSession: ARSession, videoSource: RTCVideoSource) {
        self.videoSource = videoSource
        
        // Use AR session frames
        arSession.delegate = self
    }
}

extension VideoCaptureService: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Convert ARFrame to RTCVideoFrame
        let pixelBuffer = frame.capturedImage
        let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
        let timestamp = Int64(frame.timestamp * 1_000_000_000)
        
        let rtcFrame = RTCVideoFrame(
            buffer: rtcPixelBuffer,
            rotation: ._0,
            timeStampNs: timestamp
        )
        
        videoSource?.capturer(RTCVideoCapturer(), didCapture: rtcFrame)
    }
}
```

## Step 4: Update Helper Connection Service

Modify `HelperConnectionService.swift` to actually send helper pings:

```swift
actor HelperConnectionService: HelperEscalationHandling {
    private var pendingRequests: [UUID: HelperPing.Reason] = [:]
    private weak var streamingService: VisionStreamingService?
    
    init(streamingService: VisionStreamingService) {
        self.streamingService = streamingService
    }
    
    func requestHelper(with reason: HelperPing.Reason) async throws {
        let requestID = UUID()
        pendingRequests[requestID] = reason
        let ping = HelperPing(requestID: requestID, reason: reason)
        
        // Send via Socket.IO
        guard let sessionID = streamingService?.currentSessionID,
              let socket = streamingService?.socket
        else { throw AppError.invalidState(reason: "No active session") }
        
        let data: [String: Any] = [
            "sessionID": sessionID.uuidString,
            "ping": try ping.asDictionary()
        ]
        
        socket.emit("helper-request", data)
    }
    
    func cancelPendingRequests() async {
        pendingRequests.removeAll()
    }
}
```

## Step 5: Environment Configuration

### Vision Pro App Configuration

Create a `Config.plist` or environment file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SocketServerURL</key>
    <string>https://your-socket-server.com</string>
    <key>STUNServers</key>
    <array>
        <string>stun:stun.l.google.com:19302</string>
        <string>stun:stun1.l.google.com:19302</string>
    </array>
    <key>TURNServers</key>
    <array>
        <dict>
            <key>url</key>
            <string>turn:your-turn-server.com:3478</string>
            <key>username</key>
            <string>username</string>
            <key>credential</key>
            <string>password</string>
        </dict>
    </array>
</dict>
</plist>
```

## Step 6: Testing

### Local Testing Setup

1. **Start the Socket.IO server:**
   ```bash
   cd web-helper
   npm run socket-server
   ```

2. **Start the Web Helper:**
   ```bash
   cd web-helper
   npm run dev
   ```
   Open http://localhost:3000

3. **Run Vision Pro App:**
   - Configure to connect to `http://localhost:3001` (or your computer's local IP)
   - Start streaming from the Vision Pro app
   - Video should appear in the web browser

### Troubleshooting

**No video appearing:**
- Check Socket.IO connection in both apps
- Verify WebRTC offer/answer exchange in network logs
- Check ICE candidate gathering (requires proper STUN/TURN config)

**High latency:**
- Reduce video resolution/bitrate on Vision Pro
- Use local TURN server
- Check network bandwidth

**Connection fails:**
- Configure TURN server for NAT traversal
- Check firewall settings
- Verify Socket.IO CORS settings

## Step 7: Production Deployment

### Deploy Socket.IO Server

**Recommended: Railway.app**
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login and deploy
railway login
railway init
railway up
```

Set environment variables:
```
CORS_ORIGIN=https://your-vercel-app.vercel.app
SOCKET_PORT=3001
```

### Deploy Web Helper to Vercel

```bash
cd web-helper
vercel --prod
```

Set environment variable in Vercel:
```
NEXT_PUBLIC_SOCKET_URL=https://your-socket-server.railway.app
```

### Update Vision Pro Config

Point to production Socket.IO server URL.

## Step 8: Add TURN Server (Required for Production)

For production, you need a TURN server for NAT traversal:

**Options:**
1. **Twilio TURN**: Easy setup, pay-as-you-go
2. **CoTURN**: Self-hosted open-source
3. **Xirsys**: Commercial TURN service

**Example TURN configuration:**
```swift
let iceServers = [
    RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
    RTCIceServer(
        urlStrings: ["turn:turn.example.com:3478"],
        username: "username",
        credential: "password"
    )
]
```

## Protocol Reference

### SignalingEnvelope Structure

All messages exchanged via Socket.IO follow this structure:

```json
{
  "sessionID": "uuid-string",
  "timestamp": "ISO-8601-datetime",
  "payload": {
    "type": "offer|answer|iceCandidate|helperPing|helperAck",
    "...": "payload-specific-fields"
  }
}
```

### WebRTC Offer Flow

1. Vision Pro creates offer → sends via `signaling` event
2. Web Helper receives offer → creates answer
3. Web Helper sends answer → sends via `signaling` event
4. Both exchange ICE candidates via `signaling` events
5. Connection established, video flows Vision Pro → Web Helper

### Helper Request Flow

1. Vision Pro detects low confidence → triggers `HelperConnectionService`
2. Service sends `helper-request` event with `HelperPing`
3. Web Helper displays request in UI
4. Helper clicks "Accept" → sends `helperAck` via `signaling`
5. Vision Pro receives ack → notifies user

## Security Considerations

1. **Authentication**: Add token-based auth to Socket.IO:
   ```javascript
   io.use((socket, next) => {
     const token = socket.handshake.auth.token;
     if (isValidToken(token)) {
       next();
     } else {
       next(new Error('Authentication error'));
     }
   });
   ```

2. **Session Validation**: Validate sessionIDs to prevent unauthorized access

3. **Rate Limiting**: Add rate limits to prevent abuse

4. **HTTPS/WSS**: Use secure connections in production

## Next Steps

- [ ] Implement actual WebRTC in Vision Pro app
- [ ] Add authentication layer
- [ ] Configure production TURN server
- [ ] Deploy Socket.IO server
- [ ] Deploy Web Helper to Vercel
- [ ] Test end-to-end flow
- [ ] Add analytics and monitoring

## Resources

- [WebRTC iOS Guide](https://webrtc.github.io/webrtc-org/native-code/ios/)
- [Socket.IO Swift Client](https://github.com/socketio/socket.io-client-swift)
- [Simple Peer Docs](https://github.com/feross/simple-peer)
- [TURN Server Setup](https://github.com/coturn/coturn)

