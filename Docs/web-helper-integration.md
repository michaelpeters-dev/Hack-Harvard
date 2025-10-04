# Web Helper Integration - Architecture Notes

## Overview

The `web-helper/` directory contains a Next.js web application that serves as the remote helper interface for the Context-Aware Object Reader system. It receives live video streams from Vision Pro devices via WebRTC and allows helpers to respond to assistance requests.

## Architecture Integration

### System Topology

```
Vision Pro App (visionOS) ←─┐
                             │
Mobile App (iOS)         ────┼──→ Socket.IO Server ←──→ Web Helper (Next.js/Browser)
                             │
Helper Network API       ←───┘
```

### Communication Protocol

The web helper uses the same `SignalingEnvelope` and `HelperPing`/`HelperAck` structures defined in `SharedModels/NetworkModels.swift`, ensuring protocol compatibility across the entire system.

**Key Message Types:**
- `offer`/`answer`: WebRTC session descriptions
- `iceCandidate`: ICE candidates for NAT traversal
- `helperPing`: Assistance requests (lowConfidence or manualRequest)
- `helperAck`: Helper acknowledgment with ETA

### WebRTC Flow

1. **Vision Pro** creates WebRTC offer with video track
2. Offer sent via Socket.IO to signaling server
3. **Web Helper** receives offer, creates answer
4. Answer sent back via Socket.IO
5. ICE candidates exchanged
6. Direct peer-to-peer video stream established

## Implementation Status

### Completed ✓
- Next.js 14+ application with TypeScript
- WebRTC connection handling using simple-peer
- WebSocket signaling client (Socket.IO)
- Video player component with controls
- Helper request panel (HelperPing/HelperAck UI)
- Connection status monitoring
- Stream metadata display
- Signaling server (Socket.IO)
- Vercel deployment configuration

### Remaining Work
- **Vision Pro Side:**
  - Implement actual WebRTC in `VisionStreamingService.swift`
  - Add Socket.IO client library
  - Integrate video capture from ARKit
  - Send helper requests via signaling server

- **Production:**
  - Deploy Socket.IO server (Railway/Render/Fly.io)
  - Configure TURN server for NAT traversal
  - Add authentication layer
  - Set up monitoring and logging

## File Mapping

### Web Helper ↔ Swift Models

| Web Helper (TypeScript) | Swift (SharedModels) |
|------------------------|---------------------|
| `lib/types.ts` | `NetworkModels.swift` |
| `SignalingEnvelope` | `SignalingEnvelope` |
| `HelperPing` | `HelperPing` |
| `HelperAck` | `HelperAck` |
| `IceCandidate` | `IceCandidate` |
| `SessionDescription` | `SessionDescription` |

### Service Integration

| Web Helper | Vision Pro |
|-----------|-----------|
| `lib/webrtc-connection.ts` | `VisionStreamingService.swift` |
| `lib/websocket-client.ts` | Socket.IO client (TBD) |
| `components/helper-panel.tsx` | `HelperConnectionService.swift` |

## Development Workflow

### Local Development

1. Start Socket.IO signaling server:
   ```bash
   cd web-helper
   npm run socket-server
   ```

2. Start Next.js dev server:
   ```bash
   cd web-helper
   npm run dev
   ```

3. Configure Vision Pro app to connect to `http://localhost:3001`

### Testing

- **Unit Tests**: Add to `web-helper/__tests__/`
- **Integration Tests**: Test WebRTC signaling flow
- **E2E Tests**: Test with actual Vision Pro device

## Deployment Architecture

### Recommended Setup

```
Vision Pro App ──┐
                 │
                 ├──→ Socket.IO Server (Railway/Render)
                 │    - Node.js environment
                 │    - WebSocket support
                 │    - CORS configured
                 │
                 └──→ TURN Server (Twilio/CoTURN)
                      - NAT traversal
                      - ICE relay

Web Helper ────→ Vercel (Static + Serverless)
                 - Next.js app
                 - Edge functions
                 - Global CDN
```

### Environment Variables

**Web Helper (.env.local):**
```
NEXT_PUBLIC_SOCKET_URL=https://socket-server.railway.app
```

**Socket.IO Server:**
```
CORS_ORIGIN=https://web-helper.vercel.app
SOCKET_PORT=3001
```

**Vision Pro App (Config.plist):**
```xml
<key>SocketServerURL</key>
<string>https://socket-server.railway.app</string>
```

## Security Considerations

### Current Implementation
- Basic WebRTC without authentication
- Socket.IO without access control
- Public signaling server (development only)

### Production Requirements
1. **Authentication**: Token-based auth for Socket.IO connections
2. **Session Validation**: Verify sessionIDs before relay
3. **Rate Limiting**: Prevent abuse of signaling endpoints
4. **TLS/WSS**: Encrypted connections only
5. **TURN Server**: Authenticated TURN credentials

## Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| Latency | < 500ms | Vision Pro → Web Helper |
| Frame Rate | 15-30 fps | Adjustable based on bandwidth |
| Resolution | 720p-1080p | Configurable |
| Bitrate | 500kbps-2Mbps | Adaptive |

## Next Steps

1. **Immediate** (Week 1):
   - Add WebRTC to Vision Pro app
   - Test local signaling flow
   - Verify video streaming works

2. **Short-term** (Week 2):
   - Deploy Socket.IO server
   - Configure TURN server
   - Deploy Web Helper to Vercel
   - End-to-end production test

3. **Medium-term** (Month 1):
   - Add authentication
   - Implement analytics
   - Performance optimization
   - User feedback integration

## Resources

- **Web Helper Code**: `/web-helper/`
- **Integration Guide**: `/web-helper/INTEGRATION.md`
- **API Documentation**: `/web-helper/README.md`
- **Socket.IO Server**: `/web-helper/server/socket-server.js`

## References

- WebRTC iOS: https://webrtc.github.io/webrtc-org/native-code/ios/
- Socket.IO Swift: https://github.com/socketio/socket.io-client-swift
- Next.js Docs: https://nextjs.org/docs
- Simple Peer: https://github.com/feross/simple-peer

