# Quick Start Guide - Vision Pro Web Helper

Get the web helper application running in 5 minutes.

## Prerequisites

- Node.js 18+ installed
- Terminal or command prompt
- Modern web browser (Chrome, Firefox, Safari, or Edge)

## Installation

1. **Navigate to the web-helper directory:**
   ```bash
   cd web-helper
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Create environment file:**
   ```bash
   cp .env.local.example .env.local
   ```

## Running the Application

You need **TWO terminal windows**:

### Terminal 1: Socket.IO Signaling Server

```bash
npm run socket-server
```

You should see:
```
Socket.IO signaling server running on port 3001
CORS origin: http://localhost:3000
```

### Terminal 2: Next.js Web Application

```bash
npm run dev
```

You should see:
```
▲ Next.js 15.5.4
- Local:        http://localhost:3000
- Network:      http://192.168.x.x:3000
```

## Open the Application

Open your browser to: **http://localhost:3000**

You should see:
- Dark interface with "Vision Pro Helper Stream" title
- Loading/waiting state saying "Waiting for Vision Pro stream..."
- Connection status showing signaling server is connected

## Testing Without Vision Pro

To test the interface without a Vision Pro device:

1. The UI will show the connection status and waiting state
2. Helper request panel will appear when requests come in
3. You can test the video player with a mock stream (see INTEGRATION.md)

## Next Steps

### To Connect with Vision Pro:

1. **Update Vision Pro app** to connect to Socket.IO server:
   - URL: `http://YOUR_COMPUTER_IP:3001` (use your local network IP)
   - Implement WebRTC streaming (see INTEGRATION.md)

2. **Send WebRTC offer** from Vision Pro

3. **Video should appear** in the web browser automatically

### To Deploy to Production:

See `README.md` for deployment instructions to Vercel.

## Troubleshooting

### Socket.IO server won't start
- **Error: Port 3001 already in use**
  - Solution: Kill the process using port 3001 or change the port in `server/socket-server.js`

### Web app won't start
- **Error: Port 3000 already in use**
  - Solution: Kill the process or run on a different port: `npm run dev -- -p 3001`

### Browser shows "Signaling server disconnected"
- Make sure Socket.IO server is running (Terminal 1)
- Check that `.env.local` has correct URL: `NEXT_PUBLIC_SOCKET_URL=http://localhost:3001`
- Check browser console for connection errors

### Video not showing
- This is expected without Vision Pro connected
- Make sure Vision Pro app is sending WebRTC offer
- Check Socket.IO server logs for signaling messages
- Check browser console for WebRTC errors

## Development Tips

### Hot Reload
The Next.js app supports hot reload - changes to code will automatically update the browser.

### Console Logging
Open browser DevTools (F12) to see:
- WebSocket connection status
- WebRTC signaling messages
- Connection state changes
- Any errors

### Socket.IO Logs
The Socket.IO server logs all connections and messages to the terminal.

## Architecture Overview

```
┌─────────────────┐
│  Vision Pro App │ (Swift/WebRTC)
└────────┬────────┘
         │ WebRTC Signaling
         ↓
┌─────────────────┐
│ Socket.IO Server│ (Node.js - Port 3001)
└────────┬────────┘
         │ WebSocket
         ↓
┌─────────────────┐
│  Web Helper UI  │ (Next.js - Port 3000)
└─────────────────┘
   (Your Browser)
```

## Files to Explore

- `app/page.tsx` - Main application logic
- `components/video-player.tsx` - Video player UI
- `components/helper-panel.tsx` - Helper request interface
- `lib/webrtc-connection.ts` - WebRTC peer connection handling
- `lib/websocket-client.ts` - Socket.IO client
- `server/socket-server.js` - Signaling server

## Getting Help

- **Integration with Vision Pro**: See `INTEGRATION.md`
- **Full Documentation**: See `README.md`
- **Architecture**: See `../Docs/web-helper-integration.md`

## Success Checklist

- [ ] Socket.IO server running on port 3001
- [ ] Next.js app running on port 3000
- [ ] Browser shows "Signaling server connected" (green indicator)
- [ ] UI is responsive and displays properly
- [ ] No errors in browser console or terminal

You're ready to integrate with the Vision Pro app! 🎉

