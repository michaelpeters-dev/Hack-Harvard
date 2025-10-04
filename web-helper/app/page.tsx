'use client';

import { useEffect, useState, useCallback } from 'react';
import { VideoPlayer } from '@/components/video-player';
import { HelperPanel } from '@/components/helper-panel';
import { WebRTCConnection } from '@/lib/webrtc-connection';
import { WebSocketClient } from '@/lib/websocket-client';
import type { ConnectionState, StreamMetadata, HelperPing, SignalingEnvelope } from '@/lib/types';

export default function Home() {
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [connectionState, setConnectionState] = useState<ConnectionState>('idle');
  const [metadata, setMetadata] = useState<StreamMetadata | null>(null);
  const [helperRequests, setHelperRequests] = useState<HelperPing[]>([]);
  const [webrtcConnection, setWebrtcConnection] = useState<WebRTCConnection | null>(null);
  const [wsClient, setWsClient] = useState<WebSocketClient | null>(null);
  const [sessionID, setSessionID] = useState<string>('');

  const handleSignal = useCallback((envelope: SignalingEnvelope) => {
    webrtcConnection?.handleSignal(envelope);
  }, [webrtcConnection]);

  const handleHelperRequest = useCallback((ping: HelperPing) => {
    setHelperRequests((prev) => {
      // Check if request already exists
      if (prev.some((r) => r.requestID === ping.requestID)) {
        return prev;
      }
      return [...prev, ping];
    });
  }, []);

  useEffect(() => {
    // Initialize WebRTC connection
    const rtcConnection = new WebRTCConnection(
      setConnectionState,
      setStream,
      setMetadata
    );
    setWebrtcConnection(rtcConnection);

    // Initialize WebSocket client
    const socketUrl = process.env.NEXT_PUBLIC_SOCKET_URL || 'http://localhost:3001';
    const wsConnection = new WebSocketClient(handleSignal, handleHelperRequest);
    wsConnection.connect(socketUrl);
    setWsClient(wsConnection);

    // Generate or retrieve session ID
    const storedSessionID = sessionStorage.getItem('sessionID') || crypto.randomUUID();
    sessionStorage.setItem('sessionID', storedSessionID);
    setSessionID(storedSessionID);
    rtcConnection.initialize(storedSessionID);

    // Listen for WebRTC signals to send via WebSocket
    const handleWebRTCSignal = (event: Event) => {
      const customEvent = event as CustomEvent;
      wsConnection.sendSignal(customEvent.detail);
    };
    window.addEventListener('webrtc-signal', handleWebRTCSignal);

    return () => {
      rtcConnection.destroy();
      wsConnection.disconnect();
      window.removeEventListener('webrtc-signal', handleWebRTCSignal);
    };
  }, []);

  const handleAcknowledge = (requestID: string, eta: number) => {
    if (!wsClient || !sessionID) return;

    const ack = {
      requestID,
      helperID: crypto.randomUUID(),
      eta,
    };

    wsClient.sendHelperAck(sessionID, ack);

    // Remove the request from the list
    setHelperRequests((prev) => prev.filter((r) => r.requestID !== requestID));
  };

  return (
    <div className="h-screen w-screen bg-black overflow-hidden">
      {/* Header */}
      <div className="absolute top-0 left-0 right-0 z-10 bg-gradient-to-b from-black/80 to-transparent p-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-white text-2xl font-bold">Vision Pro Helper Stream</h1>
            <p className="text-gray-400 text-sm">
              Receive and respond to live video feed from Apple Vision Pro
            </p>
          </div>
          <div className="text-right">
            <p className="text-gray-400 text-xs">Session ID</p>
            <p className="text-white text-sm font-mono">{sessionID.slice(0, 8)}...</p>
          </div>
        </div>
      </div>

      {/* Main Video Player */}
      <div className="h-full pt-20">
        <VideoPlayer
          stream={stream}
          connectionState={connectionState}
          metadata={metadata}
        />
      </div>

      {/* Helper Request Panel */}
      <HelperPanel
        helperRequests={helperRequests}
        onAcknowledge={handleAcknowledge}
      />

      {/* Connection Info Footer */}
      <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-2 text-center">
        <p className="text-gray-400 text-xs">
          {wsClient?.isConnected() ? '🟢 Signaling server connected' : '🔴 Signaling server disconnected'}
          {' • '}
          Waiting for Vision Pro stream...
        </p>
      </div>
    </div>
  );
}
