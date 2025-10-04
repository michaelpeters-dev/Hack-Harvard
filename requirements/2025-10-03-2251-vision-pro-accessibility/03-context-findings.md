# Context Findings

**Research Date:** 2025-10-03

## Technology Stack Analysis

### 1. visionOS Development (2025)

**Current Version:** visionOS 26 (released September 15, 2025)

**Key Capabilities:**
- **Eye/Gaze Tracking:** visionOS 3+ includes eye-scrolling feature allowing users to scroll by focusing gaze at window edges
  - Works across all built-in apps
  - APIs available for third-party developers
  - Note: Exact eye position data is NOT directly accessible for privacy

- **Object Detection & Tracking:**
  - visionOS 2+ supports object tracking using .usdz reference files
  - Workflow: Train ML model using Create ML's Spatial Object Tracking in Xcode 16+
  - Multiple simultaneous object tracking supported
  - ARKit provides: World Tracking, Plane Estimation, Scene Reconstruction, Image Anchoring, Skeletal Hand Tracking

- **Spatial Audio:**
  - Default experience in visionOS
  - Seamlessly blends with real-world sounds
  - PHASE framework for complex, dynamic spatial audio
  - Critical for accessibility features

**Framework Stack:**
- **SwiftUI:** Primary UI framework with 3D capabilities
- **RealityKit:** 3D graphics and spatial rendering
- **ARKit:** World tracking, scene understanding, hand tracking
- **Enhanced volumetric APIs** combining all three frameworks

### 2. AI Processing - Google Gemini API

**Recommended Model:** Gemini 2.5 Pro/Flash or 2.0 Flash (2025)

**Vision Capabilities:**
- Built multimodal from ground up (text, image, audio, video)
- Supports up to 3,600 image files per request
- Advanced features needed for this project:
  - Object detection and segmentation
  - Image captioning and classification
  - Visual question answering
  - OCR: Transcribe tables, complex layouts, charts, handwritten text
  - Document understanding for medication labels, ingredient lists

**Swift Integration:**
- Firebase AI Logic SDK (rebranded May 2025)
- Direct client SDK available for Swift on Apple platforms
- Requests sent directly from mobile/Vision Pro apps
- Real-time multimodal prompting supported

**Accessibility Use Cases Supported:**
- Medication bottle reading (OCR + object detection)
- Expiration date detection
- Allergen warning extraction from ingredient lists
- Street sign recognition
- Control panel interpretation

### 3. Real-Time Video Streaming

**Protocol:** WebRTC recommended

**Performance Metrics:**
- Sub-500ms latency (often 250ms) achievable
- Critical for safety-sensitive accessibility scenarios
- iOS/Safari support: Safari 11+ supports WebRTC (H.264 codec)
- Vision Pro likely follows iOS/visionOS WebRTC patterns

**Implementation Options:**
- Ant Media Server: Sub-0.5 second latency
- Available SDKs: iOS, React Native, Flutter, JavaScript
- QUIC transport protocol (2025) for further latency reduction
- GPU acceleration for AI + video streaming

**Architecture Pattern:**
- Mobile app captures camera feed
- Streams via WebRTC to Vision Pro
- Bidirectional: Vision Pro can stream view back to helpers
- Supports screen sharing and collaborative features

### 4. Mobile-Vision Pro Communication

**Limitations Found:**
- Limited public documentation on MultipeerConnectivity for Vision Pro
- SharePlay in FaceTime exists but may not suit custom streaming needs

**Recommended Approach:**
- **Primary:** WebRTC peer-to-peer for video streaming
- **Alternative:** Network.framework for custom protocols
- **Fallback:** Cloud relay server for NAT traversal

**Data Flow:**
```
Mobile Camera → WebRTC Stream → Vision Pro Display
Vision Pro Gaze/Selection → Control Messages → Mobile App
Gemini API ← Image Frames ← Both Devices
Gemini Results → Audio/Visual Output → Vision Pro User
```

### 5. Accessibility Features Built into visionOS

**Relevant Built-in Features:**
- **Pointer Control:** Index finger, wrist, or head as alternative pointer (critical for accessibility)
- **Live Captions:** Real-time transcriptions for deaf/hard of hearing
- **Spatial Audio:** Already optimized for accessibility
- **Braille Access:** Vision Pro can function as braille note taker
- **VoiceOver equivalent** for visionOS

**Integration Opportunities:**
- Leverage built-in pointer controls for gaze-based selection
- Integrate with Live Captions system
- Use native spatial audio APIs for directional object audio cues

## Technical Constraints & Considerations

### Performance Requirements
1. **Real-time Processing:** <250ms latency for safety
2. **Continuous Streaming:** 24/7 data flow from mobile companion
3. **Multiple Object Detection:** Simultaneous tracking/identification
4. **Spatial Awareness:** Objects positioned in 3D space with audio cues

### Privacy & Security
- Eye gaze position not directly accessible (Apple privacy policy)
- Use gaze-based UI selection instead of exact coordinates
- Consider HIPAA compliance for medical information (medication, allergens)

### Battery & Resource Management
- Continuous camera streaming on mobile device
- Continuous AI processing and display on Vision Pro
- Need power optimization strategies for extended use

### Network Requirements
- Low-latency, high-bandwidth connection required
- Fallback strategies for network interruption critical for safety
- Consider local processing options for core safety features

## Related Patterns & Best Practices

### Spatial Computing UX Patterns
- **Gaze + Pinch:** Primary interaction for object selection
- **Spatial Widgets:** Pin persistent UI elements in physical space
- **Depth Cues:** Use RealityKit materials and lighting for object emphasis
- **Audio Feedback:** Spatial audio crucial for accessibility when visual cues insufficient

### Accessibility-First Design
- Multi-modal output: Visual + Audio + Haptic (if available)
- Customizable audio speed and verbosity
- High contrast mode for visual overlays
- Configurable spatial audio volume and direction

### AI Prompt Engineering for Accessibility
- Generic prompt: "Identify all objects, text, and important information in this image. Highlight expiration dates, allergens, warnings, and safety information."
- Structured output format for parsing by app
- Confidence scores for AI uncertainty handling
- Fallback to human helper when confidence low

## Files & Components Needed (New Project)

Since codebase is empty, these are greenfield implementations:

### Vision Pro App Structure
```
VisionProApp/
├── Views/
│   ├── ImmersiveView.swift          # Main 3D spatial view
│   ├── ObjectOverlayView.swift      # Visual annotations
│   └── ControlPanelView.swift       # Settings/controls
├── Services/
│   ├── StreamingService.swift       # WebRTC connection
│   ├── GeminiService.swift          # AI API integration
│   ├── ObjectTrackingService.swift  # ARKit object tracking
│   ├── SpatialAudioService.swift    # Audio descriptions
│   └── HelperConnectionService.swift # Human helper fallback
├── Models/
│   ├── DetectedObject.swift         # Object data model
│   ├── StreamSession.swift          # Streaming session
│   └── AudioDescription.swift       # TTS content
└── Resources/
    └── ObjectModels/                # .usdz reference objects
```

### Mobile Companion App Structure
```
MobileApp/
├── Views/
│   ├── CameraView.swift             # Live camera capture
│   ├── HelperView.swift             # Remote assistance UI
│   └── StatusView.swift             # Connection status
├── Services/
│   ├── CameraService.swift          # Camera capture
│   ├── StreamingService.swift       # WebRTC streaming
│   └── GeminiService.swift          # AI processing
└── Models/
    ├── CameraFrame.swift
    └── StreamSession.swift
```

### Shared Framework
```
SharedModels/
├── NetworkModels.swift              # WebRTC data models
├── GeminiModels.swift               # API request/response
└── ProtocolDefinitions.swift       # Communication protocol
```

## Next Steps for Requirements

Based on this research, detail questions should focus on:
1. User interaction flows and edge cases
2. AI confidence thresholds for human fallback
3. Visual annotation style preferences
4. Audio description verbosity and timing
5. Network fallback behavior and safety protocols
