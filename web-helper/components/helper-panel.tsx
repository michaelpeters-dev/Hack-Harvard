'use client';

import { useState } from 'react';
import { HelperPing, HelperAck } from '@/lib/types';

interface HelperPanelProps {
    helperRequests: HelperPing[];
    onAcknowledge: (requestID: string, eta: number) => void;
}

export function HelperPanel({ helperRequests, onAcknowledge }: HelperPanelProps) {
    const [selectedRequest, setSelectedRequest] = useState<string | null>(null);
    const [eta, setEta] = useState(30); // Default 30 seconds

    const handleAcknowledge = (requestID: string) => {
        onAcknowledge(requestID, eta);
        setSelectedRequest(null);
    };

    const getReasonText = (reason: HelperPing['reason']) => {
        if (reason.type === 'lowConfidence') {
            return `Low confidence (${(reason.confidence * 100).toFixed(0)}%) detecting: ${reason.objectType}`;
        } else {
            return `Manual request: ${reason.context}`;
        }
    };

    const getReasonIcon = (reason: HelperPing['reason']) => {
        if (reason.type === 'lowConfidence') {
            return (
                <svg className="w-5 h-5 text-yellow-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                </svg>
            );
        } else {
            return (
                <svg className="w-5 h-5 text-blue-500" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M2 3a1 1 0 011-1h2.153a1 1 0 01.986.836l.74 4.435a1 1 0 01-.54 1.06l-1.548.773a11.037 11.037 0 006.105 6.105l.774-1.548a1 1 0 011.059-.54l4.435.74a1 1 0 01.836.986V17a1 1 0 01-1 1h-2C7.82 18 2 12.18 2 5V3z" />
                </svg>
            );
        }
    };

    if (helperRequests.length === 0) {
        return null;
    }

    return (
        <div className="fixed bottom-20 right-4 w-96 max-h-96 overflow-y-auto bg-gray-900 border border-gray-700 rounded-lg shadow-2xl">
            <div className="p-4 border-b border-gray-700">
                <h3 className="text-white font-semibold text-lg">Help Requests</h3>
                <p className="text-gray-400 text-sm">Vision Pro user needs assistance</p>
            </div>

            <div className="divide-y divide-gray-700">
                {helperRequests.map((request) => (
                    <div key={request.requestID} className="p-4">
                        <div className="flex items-start gap-3">
                            <div className="flex-shrink-0 mt-1">
                                {getReasonIcon(request.reason)}
                            </div>

                            <div className="flex-1 min-w-0">
                                <p className="text-white text-sm font-medium mb-1">
                                    {getReasonText(request.reason)}
                                </p>
                                <p className="text-gray-400 text-xs">
                                    Language: {request.preferredLanguage}
                                </p>

                                {selectedRequest === request.requestID ? (
                                    <div className="mt-3 space-y-2">
                                        <div>
                                            <label className="text-white text-xs font-medium block mb-1">
                                                Estimated Time (seconds):
                                            </label>
                                            <input
                                                type="number"
                                                min="5"
                                                max="300"
                                                value={eta}
                                                onChange={(e) => setEta(parseInt(e.target.value))}
                                                className="w-full px-3 py-1.5 bg-gray-800 text-white border border-gray-600 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                                            />
                                        </div>
                                        <div className="flex gap-2">
                                            <button
                                                onClick={() => handleAcknowledge(request.requestID)}
                                                className="flex-1 px-3 py-1.5 bg-green-600 hover:bg-green-700 text-white text-sm font-medium rounded transition-colors"
                                            >
                                                Accept & Help
                                            </button>
                                            <button
                                                onClick={() => setSelectedRequest(null)}
                                                className="px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-white text-sm font-medium rounded transition-colors"
                                            >
                                                Cancel
                                            </button>
                                        </div>
                                    </div>
                                ) : (
                                    <button
                                        onClick={() => setSelectedRequest(request.requestID)}
                                        className="mt-2 px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium rounded transition-colors"
                                    >
                                        Respond
                                    </button>
                                )}
                            </div>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}

