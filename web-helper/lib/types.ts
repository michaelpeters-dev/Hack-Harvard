// Type definitions matching the Swift SharedModels

export interface SignalingEnvelope {
    sessionID: string;
    timestamp: string;
    payload: SignalingPayload;
}

export type SignalingPayload =
    | { type: 'offer'; offer: SessionDescription }
    | { type: 'answer'; answer: SessionDescription }
    | { type: 'iceCandidate'; candidate: IceCandidate }
    | { type: 'helperPing'; helperPing: HelperPing }
    | { type: 'helperAck'; helperAck: HelperAck };

export interface SessionDescription {
    kind: 'offer' | 'answer';
    sdp: string;
}

export interface IceCandidate {
    sdpMid: string;
    sdpMLineIndex: number;
    candidate: string;
}

export interface HelperPing {
    requestID: string;
    reason: HelperPingReason;
    preferredLanguage: string;
}

export type HelperPingReason =
    | { type: 'lowConfidence'; objectType: string; confidence: number }
    | { type: 'manualRequest'; context: string };

export interface HelperAck {
    requestID: string;
    helperID: string;
    eta: number;
}

export interface StreamMetadata {
    timestamp: Date;
    quality: 'low' | 'medium' | 'high';
    latency: number;
    bitrate: number;
}

export type ConnectionState =
    | 'idle'
    | 'connecting'
    | 'connected'
    | 'reconnecting'
    | 'failed';

