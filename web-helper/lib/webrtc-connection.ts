import SimplePeer from 'simple-peer';
import type { SignalingEnvelope, IceCandidate, SessionDescription, StreamMetadata, ConnectionState } from './types';

export class WebRTCConnection {
    private peer: SimplePeer.Instance | null = null;
    private sessionID: string | null = null;
    private onStateChange: (state: ConnectionState) => void;
    private onStreamReceived: (stream: MediaStream) => void;
    private onMetadataUpdate: (metadata: StreamMetadata) => void;
    private reconnectAttempts = 0;
    private maxReconnectAttempts = 5;
    private reconnectDelay = 1000; // ms

    constructor(
        onStateChange: (state: ConnectionState) => void,
        onStreamReceived: (stream: MediaStream) => void,
        onMetadataUpdate: (metadata: StreamMetadata) => void
    ) {
        this.onStateChange = onStateChange;
        this.onStreamReceived = onStreamReceived;
        this.onMetadataUpdate = onMetadataUpdate;
    }

    public initialize(sessionID: string): void {
        this.sessionID = sessionID;
        this.onStateChange('connecting');

        // Create peer as receiver (initiator: false)
        this.peer = new SimplePeer({
            initiator: false,
            trickle: true,
            config: {
                iceServers: [
                    { urls: 'stun:stun.l.google.com:19302' },
                    { urls: 'stun:stun1.l.google.com:19302' },
                ],
            },
        });

        this.setupPeerListeners();
    }

    private setupPeerListeners(): void {
        if (!this.peer) return;

        this.peer.on('signal', (data) => {
            // Send signaling data to Vision Pro via WebSocket
            this.sendSignal(data);
        });

        this.peer.on('stream', (stream) => {
            console.log('Received stream from Vision Pro');
            this.onStreamReceived(stream);
            this.onStateChange('connected');
            this.reconnectAttempts = 0;
        });

        this.peer.on('connect', () => {
            console.log('WebRTC peer connected');
            this.onStateChange('connected');
        });

        this.peer.on('error', (err) => {
            console.error('WebRTC error:', err);
            this.handleConnectionError();
        });

        this.peer.on('close', () => {
            console.log('WebRTC connection closed');
            this.handleDisconnect();
        });

        this.peer.on('data', (data) => {
            try {
                const metadata = JSON.parse(data.toString()) as StreamMetadata;
                this.onMetadataUpdate(metadata);
            } catch (e) {
                console.warn('Failed to parse metadata:', e);
            }
        });
    }

    public handleSignal(envelope: SignalingEnvelope): void {
        if (!this.peer) {
            console.warn('Peer not initialized');
            return;
        }

        const { payload } = envelope;

        switch (payload.type) {
            case 'offer':
                this.peer.signal({
                    type: 'offer',
                    sdp: payload.offer.sdp,
                });
                break;

            case 'iceCandidate':
                // Convert to simple-peer ICE candidate format
                this.peer.signal({
                    candidate: {
                        candidate: payload.candidate.candidate,
                        sdpMid: payload.candidate.sdpMid,
                        sdpMLineIndex: payload.candidate.sdpMLineIndex,
                    },
                } as any); // simple-peer has looser typing for ICE candidates
                break;

            default:
                console.warn('Unhandled signal type:', payload.type);
        }
    }

    private sendSignal(data: any): void {
        // This will be called by WebSocket handler
        const envelope: Partial<SignalingEnvelope> = {
            sessionID: this.sessionID!,
            timestamp: new Date().toISOString(),
            payload: this.convertSignalToPayload(data),
        };

        // Emit via WebSocket (handled by parent component)
        window.dispatchEvent(
            new CustomEvent('webrtc-signal', { detail: envelope })
        );
    }

    private convertSignalToPayload(data: any): any {
        if (data.type === 'answer') {
            return {
                type: 'answer',
                answer: {
                    kind: 'answer',
                    sdp: data.sdp,
                },
            };
        } else if (data.candidate) {
            return {
                type: 'iceCandidate',
                candidate: {
                    sdpMid: data.candidate.sdpMid,
                    sdpMLineIndex: data.candidate.sdpMLineIndex,
                    candidate: data.candidate.candidate,
                },
            };
        }
        return data;
    }

    private handleConnectionError(): void {
        this.onStateChange('failed');
        this.attemptReconnect();
    }

    private handleDisconnect(): void {
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            this.attemptReconnect();
        } else {
            this.onStateChange('failed');
        }
    }

    private attemptReconnect(): void {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            console.error('Max reconnection attempts reached');
            return;
        }

        this.reconnectAttempts++;
        this.onStateChange('reconnecting');

        const delay = Math.min(
            this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1),
            30000 // Max 30 seconds
        );

        console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts})`);

        setTimeout(() => {
            if (this.sessionID) {
                this.initialize(this.sessionID);
            }
        }, delay);
    }

    public destroy(): void {
        if (this.peer) {
            this.peer.destroy();
            this.peer = null;
        }
        this.sessionID = null;
        this.reconnectAttempts = 0;
    }
}

