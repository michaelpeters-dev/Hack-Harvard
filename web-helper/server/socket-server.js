// Socket.IO signaling server for WebRTC
// Run this separately: node server/socket-server.js

const { createServer } = require('http');
const { Server } = require('socket.io');

const PORT = process.env.SOCKET_PORT || 3001;

const httpServer = createServer();
const io = new Server(httpServer, {
    cors: {
        origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
        methods: ['GET', 'POST'],
    },
    transports: ['websocket', 'polling'],
});

// Store connected peers
const peers = new Map(); // sessionID -> { visionPro: socket, helpers: [socket] }
const helpers = new Set(); // Available helper sockets

io.on('connection', (socket) => {
    console.log(`Client connected: ${socket.id}`);

    // Register as helper (web client)
    socket.on('register-helper', (data) => {
        console.log(`Helper registered: ${socket.id}`);
        helpers.add(socket);
        socket.isHelper = true;
        socket.emit('registered', { role: 'helper' });
    });

    // Register as Vision Pro device
    socket.on('register-vision-pro', (data) => {
        const { sessionID } = data;
        console.log(`Vision Pro registered: ${socket.id}, session: ${sessionID}`);

        if (!peers.has(sessionID)) {
            peers.set(sessionID, { visionPro: socket, helpers: [] });
        } else {
            peers.get(sessionID).visionPro = socket;
        }

        socket.sessionID = sessionID;
        socket.isVisionPro = true;
        socket.emit('registered', { role: 'vision-pro', sessionID });

        // Notify helpers that a Vision Pro is available
        helpers.forEach((helper) => {
            helper.emit('vision-pro-available', { sessionID });
        });
    });

    // WebRTC signaling relay
    socket.on('signaling', (envelope) => {
        console.log(`Signaling message: ${envelope.payload?.type || 'unknown'}`);
        const { sessionID } = envelope;

        if (!sessionID) {
            console.error('No sessionID in signaling message');
            return;
        }

        const session = peers.get(sessionID);
        if (!session) {
            console.error(`Session not found: ${sessionID}`);
            return;
        }

        // Forward signaling between Vision Pro and helpers
        if (socket.isVisionPro) {
            // Forward to all helpers in this session
            session.helpers.forEach((helper) => {
                helper.emit('signaling', envelope);
            });
            // Also broadcast to all available helpers if no one has joined yet
            if (session.helpers.length === 0) {
                helpers.forEach((helper) => {
                    helper.emit('signaling', envelope);
                });
            }
        } else if (socket.isHelper) {
            // Forward to Vision Pro
            if (session.visionPro) {
                session.visionPro.emit('signaling', envelope);
            }
            // Add helper to session if not already added
            if (!session.helpers.includes(socket)) {
                session.helpers.push(socket);
                socket.currentSessionID = sessionID;
            }
        }
    });

    // Helper request handling
    socket.on('helper-request', (data) => {
        const { sessionID, ping } = data;
        console.log(`Helper request for session ${sessionID}`);

        // Broadcast to all available helpers
        helpers.forEach((helper) => {
            helper.emit('helper-request', { sessionID, ping });
        });
    });

    // Stream metadata relay
    socket.on('stream-metadata', (data) => {
        const { sessionID, metadata } = data;
        const session = peers.get(sessionID);

        if (session) {
            session.helpers.forEach((helper) => {
                helper.emit('stream-metadata', metadata);
            });
        }
    });

    // Handle disconnection
    socket.on('disconnect', () => {
        console.log(`Client disconnected: ${socket.id}`);

        if (socket.isHelper) {
            helpers.delete(socket);

            // Remove from any session
            peers.forEach((session, sessionID) => {
                const index = session.helpers.indexOf(socket);
                if (index > -1) {
                    session.helpers.splice(index, 1);
                    console.log(`Helper removed from session ${sessionID}`);
                }
            });
        }

        if (socket.isVisionPro && socket.sessionID) {
            const session = peers.get(socket.sessionID);
            if (session) {
                // Notify helpers that Vision Pro disconnected
                session.helpers.forEach((helper) => {
                    helper.emit('vision-pro-disconnected', { sessionID: socket.sessionID });
                });
                peers.delete(socket.sessionID);
            }
        }
    });
});

httpServer.listen(PORT, () => {
    console.log(`Socket.IO signaling server running on port ${PORT}`);
    console.log(`CORS origin: ${process.env.CORS_ORIGIN || 'http://localhost:3000'}`);
});

