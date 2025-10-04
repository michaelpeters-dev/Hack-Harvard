'use client';

import { useRef, useEffect, useState } from 'react';
import { ConnectionState, StreamMetadata } from '@/lib/types';

interface VideoPlayerProps {
    stream: MediaStream | null;
    connectionState: ConnectionState;
    metadata: StreamMetadata | null;
}

export function VideoPlayer({ stream, connectionState, metadata }: VideoPlayerProps) {
    const videoRef = useRef<HTMLVideoElement>(null);
    const [isPlaying, setIsPlaying] = useState(false);
    const [volume, setVolume] = useState(1);
    const [isFullscreen, setIsFullscreen] = useState(false);

    useEffect(() => {
        if (videoRef.current && stream) {
            videoRef.current.srcObject = stream;
            videoRef.current.play().then(() => {
                setIsPlaying(true);
            }).catch((err) => {
                console.error('Error playing video:', err);
            });
        }
    }, [stream]);

    useEffect(() => {
        if (videoRef.current) {
            videoRef.current.volume = volume;
        }
    }, [volume]);

    const togglePlayPause = () => {
        if (videoRef.current) {
            if (isPlaying) {
                videoRef.current.pause();
            } else {
                videoRef.current.play();
            }
            setIsPlaying(!isPlaying);
        }
    };

    const toggleFullscreen = () => {
        if (!document.fullscreenElement) {
            videoRef.current?.requestFullscreen();
            setIsFullscreen(true);
        } else {
            document.exitFullscreen();
            setIsFullscreen(false);
        }
    };

    const getConnectionStatusColor = () => {
        switch (connectionState) {
            case 'connected':
                return 'bg-green-500';
            case 'connecting':
            case 'reconnecting':
                return 'bg-yellow-500';
            case 'failed':
                return 'bg-red-500';
            default:
                return 'bg-gray-500';
        }
    };

    const getConnectionStatusText = () => {
        switch (connectionState) {
            case 'connected':
                return 'Connected';
            case 'connecting':
                return 'Connecting...';
            case 'reconnecting':
                return 'Reconnecting...';
            case 'failed':
                return 'Connection Failed';
            default:
                return 'Idle';
        }
    };

    const getQualityLabel = () => {
        if (!metadata) return 'Unknown';
        return metadata.quality.charAt(0).toUpperCase() + metadata.quality.slice(1);
    };

    return (
        <div className="relative w-full h-full bg-black flex flex-col">
            {/* Video Element */}
            <div className="flex-1 relative flex items-center justify-center">
                <video
                    ref={videoRef}
                    className="max-w-full max-h-full"
                    autoPlay
                    playsInline
                    muted={false}
                />

                {/* Overlay when no stream */}
                {!stream && (
                    <div className="absolute inset-0 flex items-center justify-center bg-gray-900">
                        <div className="text-center">
                            <div className="mb-4">
                                <div className={`inline-block w-16 h-16 rounded-full ${getConnectionStatusColor()} animate-pulse`}></div>
                            </div>
                            <p className="text-white text-xl font-semibold">{getConnectionStatusText()}</p>
                            <p className="text-gray-400 mt-2">Waiting for Vision Pro stream...</p>
                        </div>
                    </div>
                )}

                {/* Stream Metadata Overlay */}
                {stream && metadata && (
                    <div className="absolute top-4 left-4 bg-black/70 text-white px-4 py-2 rounded-lg text-sm space-y-1">
                        <div className="flex items-center gap-2">
                            <div className={`w-2 h-2 rounded-full ${getConnectionStatusColor()}`}></div>
                            <span>{getConnectionStatusText()}</span>
                        </div>
                        <div>Quality: <span className="font-semibold">{getQualityLabel()}</span></div>
                        <div>Latency: <span className="font-semibold">{metadata.latency}ms</span></div>
                        <div>Bitrate: <span className="font-semibold">{(metadata.bitrate / 1000).toFixed(0)} kbps</span></div>
                    </div>
                )}
            </div>

            {/* Controls */}
            <div className="bg-gray-900 p-4 flex items-center gap-4">
                {/* Play/Pause Button */}
                <button
                    onClick={togglePlayPause}
                    disabled={!stream}
                    className="p-3 rounded-full bg-gray-800 hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    title={isPlaying ? 'Pause' : 'Play'}
                >
                    {isPlaying ? (
                        <svg className="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 20 20">
                            <path d="M5 4h3v12H5V4zm7 0h3v12h-3V4z" />
                        </svg>
                    ) : (
                        <svg className="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 20 20">
                            <path d="M6.3 4.1c-.3-.2-.7 0-.7.4v11c0 .4.4.6.7.4l8.5-5.5c.3-.2.3-.6 0-.8L6.3 4.1z" />
                        </svg>
                    )}
                </button>

                {/* Volume Control */}
                <div className="flex items-center gap-2">
                    <svg className="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M9.383 3.076A1 1 0 0110 4v12a1 1 0 01-1.707.707L4.586 13H2a1 1 0 01-1-1V8a1 1 0 011-1h2.586l3.707-3.707a1 1 0 011.09-.217zM12.293 7.293a1 1 0 011.414 0L15 8.586l1.293-1.293a1 1 0 111.414 1.414L16.414 10l1.293 1.293a1 1 0 01-1.414 1.414L15 11.414l-1.293 1.293a1 1 0 01-1.414-1.414L13.586 10l-1.293-1.293a1 1 0 010-1.414z" />
                    </svg>
                    <input
                        type="range"
                        min="0"
                        max="1"
                        step="0.1"
                        value={volume}
                        onChange={(e) => setVolume(parseFloat(e.target.value))}
                        className="w-24 accent-blue-500"
                        disabled={!stream}
                    />
                </div>

                {/* Spacer */}
                <div className="flex-1" />

                {/* Connection Status Badge */}
                <div className="flex items-center gap-2 px-3 py-1.5 bg-gray-800 rounded-full">
                    <div className={`w-2 h-2 rounded-full ${getConnectionStatusColor()}`}></div>
                    <span className="text-white text-sm">{getConnectionStatusText()}</span>
                </div>

                {/* Quality Indicator */}
                {metadata && (
                    <div className="px-3 py-1.5 bg-gray-800 rounded-full text-white text-sm">
                        {getQualityLabel()}
                    </div>
                )}

                {/* Fullscreen Button */}
                <button
                    onClick={toggleFullscreen}
                    disabled={!stream}
                    className="p-3 rounded-full bg-gray-800 hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    title={isFullscreen ? 'Exit Fullscreen' : 'Fullscreen'}
                >
                    {isFullscreen ? (
                        <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    ) : (
                        <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" />
                        </svg>
                    )}
                </button>
            </div>
        </div>
    );
}

