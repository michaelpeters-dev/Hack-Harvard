# Requirements Specification
## Vision Pro Accessibility App - "Context-Aware Object Reader"

**Project ID:** vision-pro-accessibility
**Created:** 2025-10-03
**Track:** HackHarvard 2025 - Human Augmentation Track
**Status:** Ready for Implementation

---

## 1. Problem Statement

Currently, there are no dedicated accessibility applications for Apple Vision Pro that leverage its unique spatial computing capabilities. Visually impaired users and those needing contextual assistance lack hands-free, gaze-aware tools to understand their environment in real-time.

Existing solutions like Be My Eyes on mobile require holding a phone and pointing, which is cumbersome and doesn't provide spatial awareness or context about multiple objects simultaneously.

## 2. Solution Overview

A dual-app system consisting of:
1. **Vision Pro App**: Hands-free, gaze-driven interface displaying object annotations with spatial audio descriptions
2. **Mobile Companion App**: Continuous camera streaming for additional context and fallback to human helpers

**Core Innovation:**
- AI-first processing via Google Gemini for instant object recognition
- Automatic fallback to human helper network when AI confidence is low
- Spatial audio queuing based on user gaze priority
- Safety-critical information prioritization (allergens, warnings, expiration dates)
- Context-agnostic design highlighting all important information

---

## 3. Functional Requirements

### 3.1 Core Features

#### F1: Real-Time Object Detection and Recognition
- **Description:** Detect multiple objects simultaneously in user's field of view
- **Behavior:**
  - Continuous processing of camera feeds from both Vision Pro and mobile device
  - Support simultaneous detection of multiple distinct objects (e.g., apple AND orange)
  - AI processing via Google Gemini multimodal API
  - Confidence scoring for each detection

#### F2: Gaze-Based Interaction
- **Description:** User selects objects to learn about using gaze
- **Behavior:**
  - Visual annotations (bounding boxes, labels) appear ONLY when user actively looks at objects
  - No persistent clutter in 3D space
  - Gaze determines priority for audio description queuing
  - Leverage visionOS eye-tracking APIs (not exact position, but UI selection)

#### F3: Spatial Audio Descriptions
- **Description:** Audio descriptions positioned at object locations in 3D space
- **Behavior:**
  - Queue descriptions sequentially based on gaze priority
  - NO overlapping audio (would be overwhelming)
  - Use visionOS PHASE framework for spatial audio
  - Descriptions include: object type, relevant details, safety information

#### F4: Safety Information Prioritization
- **Description:** Critical safety info always takes precedence
- **Behavior:**
  - Auto-detect: expiration dates, allergen warnings, hazard labels, medication info
  - Immediate interruption of other audio descriptions
  - Distinct alert sound before safety announcement
  - Visual highlighting in high-contrast color

#### F5: AI + Human Hybrid Support
- **Description:** Seamless fallback from AI to human helpers
- **Behavior:**
  - Users can manually request human helper at any time
  - System auto-pings helper network when Gemini confidence < 70% threshold
  - Real-time video stream to helpers showing Vision Pro user's view
  - Bidirectional communication: helper can annotate and speak

#### F6: 24/7 Mobile Companion Streaming
- **Description:** Continuous video stream from mobile device to Vision Pro
- **Behavior:**
  - Vision Pro requires constant mobile camera feed (dependency)
  - Mobile app streams even when screen locked or backgrounded
  - WebRTC for real-time, low-latency (<250ms) streaming
  - Automatic reconnection on network interruption

### 3.2 User Workflows

#### Workflow 1: Object Identification
1. User wears Vision Pro with mobile companion app streaming
2. User looks at object (e.g., medication bottle)
3. Visual annotation appears on object
4. User continues gaze → spatial audio description plays from object location
5. If safety info detected (expiration, allergens) → alert sound + immediate announcement

#### Workflow 2: Multiple Object Selection
1. Multiple objects detected (e.g., apple, orange, banana on table)
2. Visual annotations on all three when user scans the area
3. User gazes at orange → queued first
4. Description plays: "Orange, appears fresh, no visible blemishes"
5. User shifts gaze to banana → next in queue
6. Process continues sequentially

#### Workflow 3: AI Uncertainty → Human Helper
1. User looks at complex control panel
2. Gemini confidence score: 45% (below 70% threshold)
3. System auto-pings helper network
4. Helper connects, sees live stream from user's perspective
5. Helper provides voice guidance and/or visual annotations
6. User completes task with human assistance

---

## 4. Technical Requirements

### 4.1 Architecture

**System Architecture:**
```
┌─────────────────┐         ┌──────────────────┐
│  Mobile Device  │◄───────►│   Vision Pro     │
│  (Camera Stream)│  WebRTC │  (Primary UI)    │
└────────┬────────┘         └────────┬─────────┘
         │                           │
         │ HTTPS                     │ HTTPS
         ▼                           ▼
    ┌─────────────────────────────────┐
    │      Google Gemini API          │
    │   (Multimodal AI Processing)    │
    └─────────────────────────────────┘
         ▲
         │ WebRTC (when needed)
         │
    ┌────┴──────┐
    │  Helper   │
    │  Network  │
    └───────────┘
```

### 4.2 Technology Stack

#### Vision Pro App (visionOS 26)
- **Language:** Swift 6+
- **UI Framework:** SwiftUI with 3D capabilities
- **3D Graphics:** RealityKit for volumetric rendering
- **Spatial Computing:** ARKit (World Tracking, Object Tracking, Scene Reconstruction)
- **Audio:** PHASE framework for spatial audio
- **Streaming:** WebRTC (iOS compatible SDK)
- **AI Integration:** Firebase AI Logic SDK (Swift)

**Key Files/Components:**
```
VisionProApp/
├── Views/
│   ├── ImmersiveView.swift          # Main 3D spatial view (RealityKit)
│   ├── ObjectOverlayView.swift      # Annotation overlays with gaze tracking
│   ├── ControlPanelView.swift       # Settings and manual helper request
│   └── AlertView.swift              # Safety alert visual + audio
├── Services/
│   ├── StreamingService.swift       # WebRTC connection management
│   ├── GeminiService.swift          # Gemini API calls, confidence scoring
│   ├── ObjectTrackingService.swift  # ARKit multi-object tracking
│   ├── SpatialAudioService.swift    # PHASE audio queue + spatial positioning
│   ├── GazeTrackingService.swift    # visionOS gaze-based selection
│   └── HelperConnectionService.swift # Human helper network integration
├── Models/
│   ├── DetectedObject.swift         # Object data: id, type, confidence, position, safety_info
│   ├── StreamSession.swift          # WebRTC session state
│   ├── AudioDescription.swift       # TTS content + priority level
│   └── SafetyAlert.swift            # Critical info model
└── Resources/
    └── ObjectModels/                # .usdz reference objects for ARKit
```

#### Mobile Companion App (iOS 18+)
- **Language:** Swift 6+
- **UI Framework:** SwiftUI
- **Camera:** AVFoundation (background capture enabled)
- **Streaming:** WebRTC SDK
- **AI Integration:** Firebase AI Logic SDK (optional for redundancy)
- **Background Modes:** Camera access while locked/backgrounded

**Key Files/Components:**
```
MobileApp/
├── Views/
│   ├── CameraView.swift             # Live camera preview
│   ├── HelperView.swift             # UI when human helper connected
│   └── StatusView.swift             # Connection/streaming status
├── Services/
│   ├── CameraService.swift          # AVFoundation capture, background mode
│   ├── StreamingService.swift       # WebRTC to Vision Pro
│   └── GeminiService.swift          # Optional local AI processing
└── Models/
    ├── CameraFrame.swift            # Frame metadata
    └── StreamSession.swift          # Shared session model
```

#### Shared Framework (Swift Package)
```
SharedModels/
├── NetworkModels.swift              # WebRTC signaling protocol
├── GeminiModels.swift               # API request/response structures
└── ProtocolDefinitions.swift       # Communication protocol between apps
```

### 4.3 API & Integration Requirements

#### Google Gemini API
- **Model:** Gemini 2.5 Pro or Gemini 2.0 Flash
- **Capabilities Needed:**
  - Image understanding & object detection
  - OCR (text extraction from labels, signs, packaging)
  - Structured output with confidence scores
  - Max throughput: Up to 3,600 images per request (batch processing)

**Prompt Template:**
```
"Identify all objects, text, and important information in this image.
Prioritize and highlight:
- Expiration dates
- Allergen warnings
- Safety warnings or hazards
- Medication information
- Text content (signs, labels, instructions)

Provide structured output with confidence scores for each detection."
```

**Response Format (JSON):**
```json
{
  "objects": [
    {
      "type": "medication_bottle",
      "name": "Ibuprofen 200mg",
      "confidence": 0.95,
      "safety_info": {
        "expiration_date": "2026-03-15",
        "allergen_warnings": ["Contains lactose"],
        "critical": true
      },
      "bounding_box": {...}
    }
  ]
}
```

#### WebRTC Configuration
- **Target Latency:** <250ms (real-time for safety)
- **Codec:** H.264 (Safari/iOS standard)
- **Resolution:** 720p minimum (balance quality/latency)
- **Fallback:** Cloud relay server for NAT traversal (TURN server)
- **Signaling:** WebSocket or HTTP polling

### 4.4 Performance Requirements

| Metric | Requirement | Rationale |
|--------|-------------|-----------|
| Stream Latency | <250ms | Safety-critical accessibility |
| Object Detection Frequency | 2-5 fps | Real-time feel without overwhelming AI API |
| AI Response Time | <2 seconds | User tolerance for description |
| Auto-Helper Ping | <1 second | Quick escalation on uncertainty |
| Audio Queue Delay | <500ms after gaze | Responsive interaction |
| Background Streaming Uptime | 99%+ | Continuous dependency on mobile |

### 4.5 Data & Privacy

- **No User History Storage:** Per requirements, no local storage of interaction history
- **HIPAA Considerations:** Medical info (medication, allergens) passes through system
  - Encrypted transmission (TLS/HTTPS)
  - No server-side storage beyond session duration
  - Helper connections require explicit user consent
- **Gaze Privacy:** Exact eye position NOT accessible (Apple privacy policy)
- **Camera Privacy:** Mobile camera continuously active - requires user permission

---

## 5. Implementation Patterns & Hints

### 5.1 visionOS Patterns

**Gaze-Based Selection:**
```swift
// Use visionOS hover effects instead of exact gaze coordinates
struct ObjectAnnotation: View {
    @State private var isGazed = false

    var body: some View {
        RealityView { content in
            // Add 3D annotation
        }
        .onContinuousHover { phase in
            switch phase {
            case .active:
                isGazed = true
                triggerAudioDescription()
            case .ended:
                isGazed = false
            }
        }
    }
}
```

**Spatial Audio Queue:**
```swift
class SpatialAudioService {
    private var audioQueue: [AudioDescription] = []
    private var currentlyPlaying: AudioDescription?

    func enqueueByGazePriority(_ description: AudioDescription, gazedObject: DetectedObject) {
        // Insert at front if gazed, otherwise append
        if gazedObject.isCurrentlyGazed {
            audioQueue.insert(description, at: 0)
        } else {
            audioQueue.append(description)
        }
    }

    func playSpatialAudio(description: AudioDescription, position: SIMD3<Float>) {
        // Use PHASE for 3D positioning
        let audioSource = PHASESource(engine: phaseEngine)
        audioSource.transform = simd_float4x4(position)
        audioSource.play()
    }
}
```

### 5.2 Mobile Background Streaming

**Enable Background Camera:**
```swift
// Info.plist
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>

// CameraService.swift
class CameraService {
    func setupBackgroundCapture() {
        let captureSession = AVCaptureSession()
        captureSession.usesApplicationAudioSession = false
        // Configure for background operation
    }
}
```

### 5.3 Confidence-Based Fallback

**Auto-Helper Trigger:**
```swift
class GeminiService {
    let confidenceThreshold: Float = 0.70

    func processDetection(_ response: GeminiResponse) async {
        for object in response.objects {
            if object.confidence < confidenceThreshold {
                await HelperConnectionService.shared.pingNetwork(
                    reason: "Low confidence detection: \(object.type)"
                )
            }
        }
    }
}
```

### 5.4 Safety Alert Interruption

**Priority Audio System:**
```swift
class SpatialAudioService {
    enum AudioPriority {
        case critical  // Safety info
        case normal    // Object descriptions
    }

    func playAlert(_ alert: SafetyAlert) {
        // Interrupt current audio
        currentlyPlaying?.stop()
        audioQueue.removeAll()

        // Play alert sound
        playAlertSound()

        // Immediately announce
        playSpatialAudio(alert.description, position: alert.position)
    }
}
```

---

## 6. Acceptance Criteria

### 6.1 Core Functionality
- [ ] Vision Pro app receives continuous stream from mobile companion (24/7)
- [ ] Multiple objects detected simultaneously and differentiated
- [ ] Visual annotations appear ONLY when user looks at objects
- [ ] Spatial audio descriptions queue sequentially based on gaze
- [ ] No overlapping audio descriptions

### 6.2 Safety Features
- [ ] Expiration dates automatically detected and announced
- [ ] Allergen warnings automatically detected and announced
- [ ] Safety info interrupts other audio with distinct alert sound
- [ ] High-contrast visual highlighting for critical info

### 6.3 AI + Human Hybrid
- [ ] User can manually request human helper at any time
- [ ] System auto-pings helper network when confidence <70%
- [ ] Helper receives real-time video stream (<250ms latency)
- [ ] Bidirectional audio/visual communication with helper

### 6.4 Performance
- [ ] Stream latency consistently <250ms
- [ ] Object detection processes at 2-5 fps
- [ ] Audio descriptions start <500ms after gaze
- [ ] Mobile app continues streaming when backgrounded/locked

### 6.5 User Experience
- [ ] Hands-free operation (no manual phone pointing)
- [ ] Context-agnostic (works for any use case, not just specific scenarios)
- [ ] English audio descriptions
- [ ] Spatial awareness (audio from object locations)

---

## 7. Assumptions

### 7.1 Technical Assumptions
- **Network:** Stable WiFi or 5G connection available (real-time streaming requires bandwidth)
- **Devices:** User has both Vision Pro and iPhone with iOS 18+
- **Xcode:** Development on Xcode 16+ for visionOS 26 support
- **API Access:** Google Gemini API key obtained and configured
- **WebRTC Infrastructure:** Cloud relay server (TURN) available for NAT traversal

### 7.2 User Assumptions
- **Language:** English-speaking users for MVP
- **Permissions:** Users grant camera, microphone, and network permissions
- **Comfort:** Users comfortable wearing Vision Pro for extended periods
- **Training:** Minimal onboarding required (intuitive gaze-based interaction)

### 7.3 Scope Assumptions (Future Enhancements)
Out of scope for MVP, potential future features:
- Multi-language support
- Offline mode (local AI processing)
- User preference storage (verbosity, audio speed)
- Multiple helper profiles (family, professional)
- Integration with smart home devices
- OCR reading mode for full documents

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| WebRTC latency >250ms | High - Safety compromised | Implement local edge processing for critical detections |
| Gemini API rate limits | Medium - Service interruption | Cache recent detections, implement request throttling |
| Battery drain (continuous streaming) | High - User experience | Optimize frame rate, reduce resolution when possible |
| Network interruption | High - App unusable | Local object detection fallback, clear user warning |
| Gaze tracking accuracy | Medium - Wrong objects selected | Multi-modal selection (gaze + hand pinch confirmation) |
| Helper availability (no one online) | Medium - Fallback fails | Voicemail-style request recording, prioritize family/contacts |

---

## 9. Success Metrics (HackHarvard Demo)

- **Technical Demo:** Successfully identify 5 different object types simultaneously
- **Safety Demo:** Detect and alert on expired medication or allergen warning
- **Latency Demo:** <250ms stream latency measured and displayed
- **AI Fallback Demo:** Trigger low confidence scenario → helper connection
- **Spatial Audio Demo:** Multiple objects with positional audio descriptions
- **Background Streaming Demo:** Lock phone screen, streaming continues

---

## 10. Development Phases (Recommended)

### Phase 1: Foundation (Days 1-2)
- Setup Xcode projects (Vision Pro + Mobile apps)
- Implement basic WebRTC streaming (Mobile → Vision Pro)
- Basic camera capture with background mode

### Phase 2: Object Detection (Days 2-3)
- Integrate Google Gemini API
- Implement object detection pipeline
- Display basic visual annotations

### Phase 3: Spatial Interaction (Days 3-4)
- ARKit object tracking in 3D space
- Gaze-based selection logic
- Spatial audio with PHASE framework

### Phase 4: Safety & Intelligence (Days 4-5)
- Safety information detection (expiration, allergens)
- Audio prioritization and interruption
- Confidence scoring and helper auto-ping

### Phase 5: Polish & Demo (Day 5)
- UI refinement and accessibility
- Demo scenario testing
- Performance optimization

---

## 11. File Paths Reference

**Vision Pro App Entry Point:**
- `VisionProApp/VisionProApp.swift` - App definition
- `VisionProApp/Views/ImmersiveView.swift` - Main 3D view

**Mobile App Entry Point:**
- `MobileApp/MobileApp.swift` - App definition
- `MobileApp/Services/CameraService.swift` - Background streaming core

**Shared Models:**
- `SharedModels/GeminiModels.swift` - AI API integration
- `SharedModels/NetworkModels.swift` - WebRTC protocol

---

## 12. External Resources

**Documentation:**
- [visionOS Developer Portal](https://developer.apple.com/visionos/)
- [ARKit Object Tracking](https://developer.apple.com/documentation/arkit/tracking_and_visualizing_objects)
- [PHASE Spatial Audio](https://developer.apple.com/documentation/phase)
- [Google Gemini Swift SDK](https://developers.google.com/learn/pathways/solution-ai-gemini-getting-started-swift)
- [Firebase AI Logic](https://firebase.google.com/docs/ai-logic)
- [WebRTC iOS](https://webrtc.org/native-code/ios/)

**Similar Apps (Reference):**
- Be My Eyes (iOS) - Human helper network model
- Seeing AI (Microsoft) - Object recognition and description
- Envision AI - Text and object recognition

---

**End of Requirements Specification**
