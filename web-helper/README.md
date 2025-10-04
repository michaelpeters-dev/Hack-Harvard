# Vision Pro Helper Stream - Web Application

A Next.js web application that receives and displays live video streams from Apple Vision Pro, allowing remote helpers to assist Vision Pro users in real-time.

## Features

- **Live Video Streaming**: Receives WebRTC video stream from Vision Pro
- **Real-time Connection**: WebSocket signaling for low-latency communication
- **Helper Interface**: Respond to assistance requests from Vision Pro users
- **Stream Controls**: Play/pause, volume control, fullscreen mode
- **Connection Monitoring**: Real-time status, quality, and latency metrics
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Dark Theme**: Optimized for viewing video content

## Architecture

This application integrates with the existing Vision Pro accessibility system:

- **Vision Pro App** (Swift/visionOS) → WebRTC stream → **Web Helper** (Next.js)
- **Signaling Server** (Socket.IO) coordinates WebRTC connections
- Supports `HelperPing` and `HelperAck` messages from SharedModels

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- A running Socket.IO signaling server (included)

### Installation

```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.local.example .env.local
```

### Development

You need to run TWO servers for development:

**Terminal 1 - Next.js Application:**
```bash
npm run dev
```

**Terminal 2 - WebSocket Signaling Server:**
```bash
npm run socket-server
```

Then open [http://localhost:3000](http://localhost:3000) in your browser.

### Environment Variables

Create a `.env.local` file:

```env
NEXT_PUBLIC_SOCKET_URL=http://localhost:3001
```

For production, point to your deployed Socket.IO server.

## Project Structure

```
web-helper/
├── app/
│   ├── page.tsx              # Main application page
│   ├── layout.tsx            # Root layout
│   ├── globals.css           # Global styles
│   └── api/
│       └── socket/           # API route info
├── components/
│   ├── video-player.tsx      # Video player with controls
│   └── helper-panel.tsx      # Helper request interface
├── lib/
│   ├── types.ts              # TypeScript type definitions
│   ├── webrtc-connection.ts  # WebRTC peer connection handler
│   └── websocket-client.ts   # WebSocket signaling client
└── server/
    └── socket-server.js      # Socket.IO signaling server
```

## Integration with Vision Pro

### Signaling Protocol

The web app uses the same signaling protocol defined in `SharedModels/NetworkModels.swift`:

```typescript
interface SignalingEnvelope {
  sessionID: string;
  timestamp: string;
  payload: SignalingPayload;
}
```

Supported payload types:
- `offer` / `answer` - WebRTC session descriptions
- `iceCandidate` - ICE candidates for NAT traversal
- `helperPing` - Assistance requests from Vision Pro
- `helperAck` - Helper acknowledgment responses

### Vision Pro Setup

1. Update `VisionStreamingService.swift` to connect to your signaling server
2. Implement WebRTC offer generation in Vision Pro app
3. Send signaling messages to the Socket.IO server
4. Forward video track through WebRTC peer connection

## Deployment

### Deploy Next.js App to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel
```

### Deploy Socket.IO Server

The Socket.IO signaling server needs a separate Node.js environment:

**Option 1: Vercel Serverless Function** (for light usage)
- Not recommended due to WebSocket limitations

**Option 2: Railway / Render / Fly.io** (recommended)
```bash
# Deploy server/socket-server.js to a Node.js hosting service
# Set environment variable: CORS_ORIGIN=https://your-vercel-app.vercel.app
```

**Option 3: Self-hosted**
```bash
# On your server
cd server
node socket-server.js
```

### Environment Variables for Production

Set in Vercel:
```
NEXT_PUBLIC_SOCKET_URL=https://your-socket-server.com
```

Set in Socket.IO server:
```
CORS_ORIGIN=https://your-vercel-app.vercel.app
SOCKET_PORT=3001
```

## API Reference

### WebSocket Events (Client → Server)

- `register-helper`: Register web client as available helper
- `signaling`: Send WebRTC signaling messages
- `helper-ack`: Acknowledge and accept help request

### WebSocket Events (Server → Client)

- `registered`: Confirmation of registration
- `signaling`: WebRTC signaling from Vision Pro
- `helper-request`: New assistance request from user
- `stream-metadata`: Video quality and latency info
- `vision-pro-available`: Vision Pro device connected
- `vision-pro-disconnected`: Vision Pro device left

## Browser Compatibility

- Chrome/Edge 90+
- Firefox 88+
- Safari 14.1+ (iOS/macOS)
- WebRTC and WebSocket support required

## Security Considerations

- **HTTPS**: Deploy with SSL/TLS in production
- **Authentication**: Add auth layer for helper access (not included)
- **Session Management**: Implement proper session validation
- **TURN Server**: Configure for NAT traversal in production
- **Rate Limiting**: Add to prevent abuse

## Troubleshooting

### Video not showing
- Check that Socket.IO server is running
- Verify `NEXT_PUBLIC_SOCKET_URL` is correct
- Ensure Vision Pro app is sending WebRTC offer
- Check browser console for WebRTC errors

### Connection keeps dropping
- Check firewall settings
- Configure TURN servers for NAT traversal
- Monitor network quality on both sides

### High latency
- Reduce video bitrate in Vision Pro app
- Use TURN server closer to users
- Check network bandwidth

## Contributing

This is part of the HackHarvard 2025 Context-Aware Object Reader project.

## License

MIT

## Related Projects

- `HarvardHack25/` - Vision Pro spatial app (Swift)
- `MobileApp/` - iOS companion app (Swift)
- `SharedModels/` - Shared protocol definitions

## Support

For issues related to:
- Web app: Check browser console and network tab
- WebRTC: Check ICE candidate gathering and STUN/TURN config
- Vision Pro integration: See Vision Pro app documentation
