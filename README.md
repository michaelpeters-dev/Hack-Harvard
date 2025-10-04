# Context-Aware Object Reader

Welcome to the dual-app accessibility platform for Apple Vision Pro and iOS companion devices. This repo contains the implementation scaffold for the "Context-Aware Object Reader" defined in the HackHarvard 2025 requirements.

## Repo Layout

- `VisionProApp/` – visionOS spatial experience (SwiftUI, RealityKit, PHASE) with modular services and view models
- `MobileApp/` – iOS companion for 24/7 streaming (SwiftUI, AVFoundation, WebRTC skeleton)
- `SharedModels/` – Swift package hosting shared network and AI models plus service protocols
- `Docs/` – living architecture docs and design notes
- `requirements/` – canonical product requirements and discovery artifacts

## Getting Started

1. Install Xcode 16+ with visionOS 26 SDK.
2. Open the workspace you create combining VisionProApp, MobileApp, and SharedModels.
3. Provide environment variables for Gemini API credentials before wiring real network calls.

## Development Status

The codebase currently provides:

- Dependency-injected services respecting SOLID + DRY principles.
- SwiftUI views and view models for both apps, ready to hook into real devices.
- Stubs for WebRTC, Gemini, PHASE, and helper network integrations flagged via `AppError.notImplemented`.
- Shared models and protocol definitions to keep both apps in sync.

## Next Steps

- Implement actual WebRTC signaling and transmission using the SharedModels contracts.
- Replace placeholder Gemini service calls with Firebase AI Logic / Google Gemini SDK.
- Wire ARKit spatial anchors, gaze tracking, and PHASE audio playback on VisionPro.
- Connect AVFoundation capture output to WebRTC publisher on the mobile app.
- Backfill unit/UI tests as modules gain real behavior.

The Zen of Python might be guiding the vibe, but the code stays Swift-clean and puppy-approved. 🐶
