# Quick Reference - Vision Pro Web Helper

## Commands

### Development
```bash
# Install dependencies
npm install

# Start Socket.IO server (Terminal 1)
npm run socket-server

# Start Next.js dev server (Terminal 2)
npm run dev
```

### Production
```bash
# Deploy to Vercel
vercel --prod

# Build for production
npm run build
npm start
```

## URLs

- **Dev App**: http://localhost:3000
- **Dev Socket.IO**: http://localhost:3001
- **Production**: Configure in `.env.local`

## Environment Variables

```env
# .env.local
NEXT_PUBLIC_SOCKET_URL=http://localhost:3001  # Development
# NEXT_PUBLIC_SOCKET_URL=https://your-socket-server.com  # Production
```

## File Locations

| Purpose | File |
|---------|------|
| Main app | `app/page.tsx` |
| Video player | `components/video-player.tsx` |
| Helper requests | `components/helper-panel.tsx` |
| WebRTC logic | `lib/webrtc-connection.ts` |
| WebSocket logic | `lib/websocket-client.ts` |
| Type definitions | `lib/types.ts` |
| Signaling server | `server/socket-server.js` |

## Key Types

```typescript
// Connection states
type ConnectionState = 'idle' | 'connecting' | 'connected' | 'reconnecting' | 'failed'

// Signaling envelope
interface SignalingEnvelope {
  sessionID: string
  timestamp: string
  payload: SignalingPayload
}

// Helper request
interface HelperPing {
  requestID: string
  reason: HelperPingReason
  preferredLanguage: string
}

// Helper response
interface HelperAck {
  requestID: string
  helperID: string
  eta: number
}
```

## WebSocket Events

### Client → Server
- `register-helper` - Register as available helper
- `signaling` - Send WebRTC signals
- `helper-ack` - Respond to help request

### Server → Client
- `registered` - Registration confirmed
- `signaling` - Receive WebRTC signals
- `helper-request` - New help request
- `stream-metadata` - Video quality info
- `vision-pro-available` - Device connected
- `vision-pro-disconnected` - Device left

## Common Tasks

### Add New UI Component
1. Create in `components/` directory
2. Import in `app/page.tsx`
3. Add TypeScript types in `lib/types.ts`

### Modify Video Controls
Edit `components/video-player.tsx` controls section

### Change Connection Logic
Edit `lib/webrtc-connection.ts` or `lib/websocket-client.ts`

### Add Signaling Event
1. Add handler in `server/socket-server.js`
2. Add client listener in `lib/websocket-client.ts`
3. Update types in `lib/types.ts`

## Debugging

### Browser Console
```javascript
// Check WebRTC state
document.querySelector('video').srcObject

// Check WebSocket state
// Look for connection logs
```

### Server Logs
```bash
# Socket.IO server shows all events
# Look for: "Client connected", "Signaling message", etc.
```

### Common Issues

**Video not appearing:**
- Check Socket.IO server running (port 3001)
- Check browser console for WebRTC errors
- Verify Vision Pro is sending offer

**Connection drops:**
- Check network stability
- Verify TURN server configured (production)
- Check firewall settings

**High latency:**
- Reduce video bitrate in Vision Pro
- Check network bandwidth
- Use closer TURN server

## Architecture Quick Reference

```
Vision Pro (Swift)
    ↓ WebRTC Offer
Socket.IO Server (Node.js)
    ↓ Relay Signaling
Web Helper (Next.js)
    ↓ WebRTC Answer
Vision Pro ←─── P2P Video ───→ Web Helper
```

## Port Usage

- `3000` - Next.js development server
- `3001` - Socket.IO signaling server

## Dependencies

```json
{
  "next": "15.5.4",
  "react": "19.1.0",
  "simple-peer": "^9.11.1",
  "socket.io-client": "^4.8.1"
}
```

## Documentation Map

| Document | Purpose |
|----------|---------|
| `README.md` | Complete documentation |
| `QUICKSTART.md` | 5-minute setup |
| `INTEGRATION.md` | Vision Pro integration |
| `FEATURES.md` | Feature overview |
| `QUICK-REFERENCE.md` | This file |

## Code Snippets

### Send Signaling Message
```typescript
wsClient.sendSignal({
  sessionID: 'uuid',
  timestamp: new Date().toISOString(),
  payload: { type: 'offer', offer: {...} }
})
```

### Handle Helper Request
```typescript
const handleAcknowledge = (requestID: string, eta: number) => {
  wsClient.sendHelperAck(sessionID, {
    requestID,
    helperID: crypto.randomUUID(),
    eta
  })
}
```

### Initialize WebRTC
```typescript
const connection = new WebRTCConnection(
  setConnectionState,
  setStream,
  setMetadata
)
connection.initialize(sessionID)
```

## Testing Checklist

- [ ] Socket.IO server starts (port 3001)
- [ ] Next.js app starts (port 3000)
- [ ] Browser shows "Signaling server connected"
- [ ] No console errors
- [ ] UI renders correctly
- [ ] (With Vision Pro) Video appears
- [ ] (With Vision Pro) Helper requests work

## Support Resources

- **Integration**: See `INTEGRATION.md`
- **Setup Issues**: See `QUICKSTART.md`
- **Features**: See `FEATURES.md`
- **Architecture**: See `../Docs/web-helper-integration.md`

## Version Info

- Next.js: 15.5.4
- React: 19.1.0
- Node.js: 18+ required
- TypeScript: 5+

---

**Quick Start**: Run `npm install`, `npm run socket-server` (Terminal 1), `npm run dev` (Terminal 2), open http://localhost:3000

