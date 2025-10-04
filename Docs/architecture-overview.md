# Context-Aware Object Reader – Architecture Overview

## Goals
- Deliver the dual-app experience described in requirements, enabling Vision Pro users to receive contextual, spatialized descriptions of their surroundings.
- Maintain strict adherence to SOLID, DRY, and YAGNI principles so future iterations stay manageable.
- Keep every source file comfortably under 600 lines by aggressively modularizing services and views.

## High-Level Topology
```
MobileApp (iOS 18+) ── WebRTC ── VisionProApp (visionOS 26)
         │                              │
         └───── HTTPS ───── GeminiService ───── Google Gemini API
                                       │
                               HelperConnectionService ── Human Helpers
```

## Module Breakdown
- **VisionProApp/**
  - `Views/` – SwiftUI + RealityKit immersive views and overlays responding to gaze.
  - `Services/` – Modular services for streaming, AI calls, spatial audio, gaze tracking, and helper coordination.
  - `Models/` – Data structures backing annotations, audio queues, and streaming state.
  - `Resources/` – Placeholder for .usdz reference objects.
- **MobileApp/**
  - `Views/` – Lightweight SwiftUI views for camera status and helper escalation.
  - `Services/` – Background-capable camera capture and WebRTC streaming logic.
  - `Models/` – Frame metadata and connection state.
- **SharedModels/**
  - Swift Package containing networking payloads and Gemini response types shared across both apps.

## Key Cross-Cutting Concerns
- **WebRTC Signaling:** Defined in `SharedModels/NetworkModels.swift` with protocols for both apps to conform to, supporting substitution in tests.
- **AI Processing:** Encapsulated in `GeminiService` (both apps) using dependency inversion so unit tests can swap in mock processors.
- **Safety Prioritization:** Dedicated `SafetyAlert` model and `SpatialAudioService` queue ensure interruptions obey critical precedence.
- **Gaze Interaction:** `GazeTrackingService` surfaces observable state without exposing private APIs; views subscribe reactively.

## Non-Functional Requirements Handling
- **Performance Targets:** Services expose async APIs to enable throttling (e.g., 2–5 fps detection). A `DetectionRateLimiter` helper will enforce budgets.
- **Privacy:** No state persisted beyond session: models hold in-memory data only. Networking layer enforces TLS and redacts sensitive fields when logging.
- **Resilience:** Streaming services perform automatic reconnection with exponential backoff capped to protect battery life.

## Development Phases Recap
1. Foundation: stand up project skeletons and shared package.
2. Detection: integrate Gemini API wrappers with test doubles.
3. Spatial Interaction: wire ARKit anchors to gaze-driven annotations.
4. Safety Layer: alert prioritization and human helper escalation.
5. Polish: demo scripts, performance tuning, and accessibility audits.

## Outstanding Questions
- TURN / signaling infrastructure specifics remain TBD – expect to stub with local mocks until provided.
- Helper network API contract requires clarification; current placeholder assumes WebSocket signaling.

This document should evolve as implementation details harden, but the current scaffold maps directly to the requirement specification’s architecture section.
