import { io, Socket } from 'socket.io-client';
import type { SignalingEnvelope, HelperPing, HelperAck } from './types';

export class WebSocketClient {
    private socket: Socket | null = null;
    private onSignal: (envelope: SignalingEnvelope) => void;
    private onHelperRequest: (ping: HelperPing) => void;
    private reconnectAttempts = 0;
    private maxReconnectAttempts = 10;

    constructor(
        onSignal: (envelope: SignalingEnvelope) => void,
        onHelperRequest: (ping: HelperPing) => void
    ) {
        this.onSignal = onSignal;
        this.onHelperRequest = onHelperRequest;
    }

    public connect(url: string): void {
        this.socket = io(url, {
            transports: ['websocket', 'polling'],
            reconnection: true,
            reconnectionDelay: 1000,
            reconnectionDelayMax: 5000,
            reconnectionAttempts: this.maxReconnectAttempts,
        });

        this.setupSocketListeners();
    }

    private setupSocketListeners(): void {
        if (!this.socket) return;

        this.socket.on('connect', () => {
            console.log('WebSocket connected');
            this.reconnectAttempts = 0;
            // Register as a helper
            this.socket?.emit('register-helper', { role: 'web-helper' });
        });

        this.socket.on('disconnect', (reason) => {
            console.log('WebSocket disconnected:', reason);
        });

        this.socket.on('connect_error', (error) => {
            console.error('WebSocket connection error:', error);
            this.reconnectAttempts++;
        });

        // WebRTC signaling messages
        this.socket.on('signaling', (envelope: SignalingEnvelope) => {
            console.log('Received signaling message:', envelope.payload.type);
            this.onSignal(envelope);
        });

        // Helper requests from Vision Pro
        this.socket.on('helper-request', (data: { sessionID: string; ping: HelperPing }) => {
            console.log('Received helper request:', data.ping);
            this.onHelperRequest(data.ping);
        });

        // Listen for custom events from Vision Pro
        this.socket.on('stream-metadata', (metadata: any) => {
            console.log('Received stream metadata:', metadata);
        });
    }

    public sendSignal(envelope: Partial<SignalingEnvelope>): void {
        if (!this.socket?.connected) {
            console.warn('Socket not connected, cannot send signal');
            return;
        }

        this.socket.emit('signaling', envelope);
    }

    public sendHelperAck(sessionID: string, ack: HelperAck): void {
        if (!this.socket?.connected) {
            console.warn('Socket not connected, cannot send ack');
            return;
        }

        const envelope: SignalingEnvelope = {
            sessionID,
            timestamp: new Date().toISOString(),
            payload: {
                type: 'helperAck',
                helperAck: ack,
            },
        };

        this.socket.emit('signaling', envelope);
    }

    public disconnect(): void {
        if (this.socket) {
            this.socket.disconnect();
            this.socket = null;
        }
    }

    public isConnected(): boolean {
        return this.socket?.connected ?? false;
    }
}

