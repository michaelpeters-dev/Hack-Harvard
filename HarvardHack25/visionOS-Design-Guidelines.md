# visionOS Design Guidelines & Liquid Glass Design Language

Comprehensive guide to designing for Apple Vision Pro and visionOS, incorporating Liquid Glass design principles.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Liquid Glass Design Language](#liquid-glass-design-language)
3. [Core visionOS Concepts](#core-visionos-concepts)
4. [Scene Types](#scene-types)
5. [Spatial Design Principles](#spatial-design-principles)
6. [Ergonomics and Comfort](#ergonomics-and-comfort)
7. [Materials, Depth, and Layers](#materials-depth-and-layers)
8. [Ornaments](#ornaments)
9. [Interaction Patterns](#interaction-patterns)
10. [Typography and Accessibility](#typography-and-accessibility)
11. [Spatial Audio](#spatial-audio)
12. [Best Practices](#best-practices)

---

## Introduction

visionOS provides an infinite 3D space where people can engage with apps while staying connected to their surroundings. Inspired by the depth and dimensionality of visionOS, Apple introduced Liquid Glass in 2025 as a unified design language that spans all Apple platforms.

This guide combines official Apple Human Interface Guidelines for visionOS with the principles of Liquid Glass design to help you create compelling, comfortable, and accessible spatial experiences.

---

## Liquid Glass Design Language

### Overview

Announced at WWDC 2025 (June 9, 2025), Liquid Glass is Apple's unified visual theme for the graphical user interfaces across iOS, iPadOS, macOS, watchOS, tvOS, and visionOS.

### Design Philosophy

**Core Principle**: "It combines the optical qualities of glass with a fluidity only Apple can achieve, as it transforms depending on your content or context."

### Inspiration and Evolution

Liquid Glass builds on learnings from:
- Aqua user interface of Mac OS X
- Real-time blurs of iOS 7
- Fluidity of iPhone X
- Flexibility of the Dynamic Island
- Immersive interface of visionOS

### Visual Characteristics

**Material Properties**:
- Translucent material that reflects and refracts surroundings
- Behaves like real-world glass
- Uses real-time rendering
- Dynamically reacts to movement with specular highlights

**Color Adaptation**:
- Intelligently adapts between light and dark environments
- Creates visual coherence across different contexts

**Lensing**:
- Primary visual definition of Liquid Glass
- Refracts and reflects any element placed behind it
- Uses realistic lighting and shaders to look like real glass

### Functional Characteristics

**Dynamic Transformation**:
- Controls and navigation fluidly morph and transform
- Dynamically transforms based on content and context
- Creates a "lively experience" across platforms

**Layering**:
- Acts as a "distinct functional layer" above apps
- Provides greater focus on content
- Extends from small UI elements (buttons, switches) to larger interfaces

**Hardware Integration**:
- Adapts to rounded hardware corners
- Takes advantage of Apple's advances in hardware, silicon, and graphics technologies

### Platform Integration

Liquid Glass applies to:
- Lock Screen
- Home Screen
- Notifications
- Control Center
- App icons
- Widgets
- Tab bars
- Sidebars

### Personalization

Enables personalization while maintaining familiarity across the Apple ecosystem.

---

## Core visionOS Concepts

### Spatial Canvas

visionOS provides an infinite 3D space where apps and content can be positioned anywhere in the user's surroundings.

### Shared Space vs Full Space

**Shared Space**:
- Default launch environment
- Apps exist side by side (similar to Mac desktop)
- Apps can use windows and volumes
- People can reposition elements freely

**Full Space**:
- Dedicated space where only one app's content appears
- Can use windows and volumes
- Create unbounded 3D content
- Open portals to different worlds
- Fully immerse people in an environment

### Key Recommendation

Always launch your app in the Shared Space using windows or volumes, giving users the freedom to enter immersive space and choose their preferred level of immersion. Starting in a window helps people orient themselves before transporting them to a fully immersive experience.

---

## Scene Types

visionOS offers three scene types that can be mixed and matched to create the right moments for your content.

### Windows

**Description**:
- Built with SwiftUI
- Contain traditional views and controls
- Can add depth with 3D content
- Can create one or more windows per app

**Material**:
- Unmodifiable background glass material
- Lets light and physical/virtual objects show through

**Use Cases**:
- Traditional app interfaces
- Control panels
- Content browsers

### Volumes

**Description**:
- SwiftUI scenes showcasing 3D content
- Use RealityKit or Unity
- Viewable from any angle
- Can exist in Shared Space or Full Space

**Use Cases**:
- 3D object viewers
- Sculptural content
- Interactive 3D experiences

### Immersive Spaces

**Description**:
- Extend beyond windows and volumes
- Position content anywhere in user's surroundings
- Offer fully immersive experiences
- Only available in Full Space

**Capabilities**:
- Unbounded 3D content
- Environmental experiences
- Portal views to different worlds

**Design Guideline**:
Don't place people into a fully immersive experience immediately—ensure they're oriented in your app first.

---

## Spatial Design Principles

### Spatial Layout

Spatial layout techniques help take advantage of the infinite canvas of Apple Vision Pro and present content in engaging, comfortable ways.

### Depth Communication

**Hierarchy Through Depth**:
- Use depth to communicate importance
- Advance interactive elements along z-axis to help them stand out
- Recede background windows to communicate deprioritization

**Strategic Integration**:
- Add depth to enhance value, clarity, or delight
- Don't add depth for its own sake

**Automatic Depth**:
- System automatically adds depth to 2D windows through:
  - Color
  - Temperature
  - Reflections
  - Shadows

### Visual Cues

The Apple Vision Pro system uses multiple visual cues to create depth perception without requiring true 3D positioning.

---

## Ergonomics and Comfort

### Field of View

**Primary Principle**: Comfort should guide experiences.

**Best Practices**:
- Keep main content in the field of view
- Minimize neck and body movement requirements
- Center important content for eye comfort
- Reserve edges for secondary actions

### Viewing Distance

**Focal Distance**: Approximately 6 feet
- Eyes focus as if objects were 6 feet away
- Applies regardless of virtual distance in digital space

### Content Placement

**Center Area**: Main content and primary interactions
**Peripheral Areas**: Secondary actions and contextual information

### Comfort Optimization

- Design interfaces that respond to eye movements
- Optimize for eye and neck comfort
- Prioritize users' safety and comfort
- Keep important UI elements within comfortable field of view

---

## Materials, Depth, and Layers

### Materials

**Definition**: Visual effects that create a sense of depth, layering, and hierarchy between foreground and background elements.

**visionOS Glass Material**:
- Unmodifiable background for windows
- Lets light show through
- Allows physical and virtual objects to be visible
- Integrates with Liquid Glass design language

### Depth and Layering

**Hierarchy Communication**:
- Foreground elements appear in front
- Background elements recede along z-axis
- Interactive elements can advance forward

**Implementation**:
- Automatic depth cues from system
- Manual depth positioning for 3D content
- Combine with materials for enhanced effect

### Visual Coherence

Maintain visual coherence by:
- Using consistent material treatments
- Respecting depth hierarchy
- Balancing transparency and solidity
- Integrating with surrounding environment

---

## Ornaments

### Definition

Ornaments present controls and information related to a window without crowding or obscuring the window's contents.

### Characteristics

**Positioning**:
- Float slightly in front of associated windows or objects
- Visually distinct from window content

**Sizing Guidelines**:
- Equal width or narrower than associated window
- Maintain visual coherence

### Design Considerations

- Don't crowd window contents
- Keep controls accessible
- Maintain spatial relationship with parent window
- Use for contextual controls and information

---

## Interaction Patterns

### Eye Tracking (Gaze Input)

**Primary Function**: Targeting system (like mouse pointer or touchscreen hover)

**How It Works**:
1. Look at a virtual object to identify it as a target
2. Object highlights to show it's targeted
3. Confirm selection with pinch gesture

**Privacy**:
- Direct continuous gaze data is not accessible to apps
- All gaze information is abstracted
- Protects user privacy while enabling interaction

### Gestures

**Standard Gestures**:
- **Tap**: Pinch thumb and index finger together
- **Swipe**: Quick directional movement
- **Drag**: Pinch and hold while moving
- **Touch and Hold**: Sustained pinch
- **Double-tap**: Two quick pinches
- **Zoom**: Two-finger pinch movement
- **Rotate**: Two-finger rotation gesture

**Framework Support**:
- SwiftUI provides built-in gesture support
- UIKit handles gestures across platforms

### Hands-Free Control

**Dwell Control**:
- Enable in Settings for hands-free operation
- Hold gaze on element for set period
- Ring-shaped progress bar indicates activation
- Can scroll by looking at top/bottom of window (visionOS 3+)

### Alternative Input Methods

**Pointer Control**:
- Index finger
- Wrist
- Head
- Designed for accessibility

**Voice Control**:
- Interact entirely with voice
- Can combine with eye tracking

### Design Guidelines

- Adopt standard system gestures
- Provide visual feedback for targeting
- Design for eye-first interaction
- Support alternative input methods for accessibility

---

## Typography and Accessibility

### System Font

**SF Pro**:
- Exceptional legibility across Apple platforms
- Optimized for visionOS environments

### Typography Adjustments for visionOS

**Default Color**: White
- High contrast against darker backgrounds
- Most legible on glass materials

**Font Weight**:
- Body text uses **medium weight** (vs. regular on iOS)
- Improved contrast and visibility
- Thicker strokes for better readability
- Especially important for users with vision impairments

### Vibrancy

**Purpose**: Enhance contrast and legibility

**Modes**:
- **Primary**: Standard text
- **Secondary**: Descriptive text (footnotes, subtitles)
- **Tertiary**: Inactive elements (use only when high legibility isn't crucial)

### visionOS-Specific Font Styles

**Extra Large Title 1 & 2**:
- Ideal for prominent, attention-grabbing headings
- Best for wide, editorial-style layouts

### Contrast Guidelines

- White text recommended for most contexts
- If using other colors, ensure strong contrast with background
- Test legibility on glass materials

### Accessibility Features

**Increase Contrast**:
- Improves legibility
- Makes text stand out more

**Bold Text**:
- Makes all text heavier
- Global setting

**Larger Text**:
- Adjustable slider for text size
- Extended size options available

### Best Practices

- Use bolder font weights for body text
- Apply appropriate vibrancy levels
- Ensure contrast meets accessibility standards
- Test on actual glass materials
- Support Dynamic Type

---

## Spatial Audio

### Overview

Spatial Audio is the default experience in visionOS and is crucial to creating compelling experiences on Apple Vision Pro.

### PHASE Framework

**Purpose**: Create complex, dynamic Spatial Audio experiences

**Capabilities**:
- Advanced spatial positioning
- Dynamic soundscapes
- Environmental audio effects

**Recommended For**:
- Games
- Immersive experiences
- Complex audio requirements

### Implementation Guidelines

**Audio File Format**:
- Use **mono files** for spatial sound
- System handles spatialization

**Spatial Positioning**:
- Position sound to come directly from interactive items
- System uses surroundings for appropriate reverberation
- System adds texture based on environment

**Object Attachment**:
- Attach spatial audio to 3D objects
- Use Reality Composer Pro for setup
- Audio follows object position

### Design Principles

**Varied Repetitive Sounds**:
- Avoid identical repeated sounds
- Add variation to maintain interest

**Moments of Sonic Delight**:
- Use sound to enhance interactions
- Create satisfying audio feedback

**Spatial Placement**:
- Match audio position to visual elements
- Use directionality to guide attention

### Technical Considerations

- Spatial Audio works automatically in visionOS
- System handles head tracking
- Supports Dolby Atmos
- Integrates with RealityKit entities

### Developer Resources

- "Explore immersive sound design" WWDC session
- Apple Developer Documentation on playing spatial audio
- Reality Composer Pro for audio setup

---

## Best Practices

### App Launch and Orientation

1. **Always start in Shared Space** with windows or volumes
2. Let users choose their level of immersion
3. Orient users before transitioning to immersive experiences
4. Don't immediately place users in fully immersive environments

### Spatial Design

1. **Prioritize comfort** in all design decisions
2. **Center important content** for optimal viewing
3. **Use depth strategically** to add value, not just visual flair
4. **Maintain visual coherence** across scenes and spaces

### Interaction Design

1. **Design for eye-first interaction** (look, then gesture)
2. **Provide clear visual feedback** for targeting
3. **Support standard gestures** for consistency
4. **Enable alternative input methods** for accessibility

### Visual Design

1. **Embrace Liquid Glass principles** for consistency with platform
2. **Use white text as default** for optimal legibility
3. **Apply appropriate vibrancy** for text hierarchy
4. **Test on actual glass materials** for real-world appearance

### Audio Design

1. **Use spatial audio** to enhance immersion
2. **Position sound sources** accurately relative to visual elements
3. **Add variety** to repetitive sounds
4. **Create moments of sonic delight** for satisfying interactions

### Accessibility

1. **Support all text size options**
2. **Ensure sufficient contrast** (especially on glass)
3. **Enable hands-free control** options
4. **Test with accessibility features** enabled

### Content Organization

1. **Mix and match scene types** appropriately
2. **Use windows** for traditional interfaces
3. **Use volumes** for 3D content
4. **Reserve immersive spaces** for deeply engaging experiences

### Ergonomics

1. **Keep critical UI within comfortable field of view**
2. **Minimize required neck movement**
3. **Consider 6-foot focal distance** in design
4. **Test for extended use comfort**

### Materials and Depth

1. **Leverage system-provided glass materials**
2. **Use depth to communicate hierarchy**
3. **Advance interactive elements** along z-axis
4. **Recede background elements** appropriately

### Ornaments

1. **Don't crowd window contents**
2. **Keep ornaments equal or narrower than windows**
3. **Maintain spatial relationships** clearly
4. **Use for contextual controls** not primary navigation

---

## Developer Resources

### Official Documentation

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [Designing for visionOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-visionos)
- [Liquid Glass Documentation](https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)

### WWDC Sessions

- Meet Liquid Glass (WWDC 2025)
- Dive deep into volumes and immersive spaces (WWDC 2024)
- Explore immersive sound design

### Technical References

- [Materials Guidelines](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Ornaments Guidelines](https://developer.apple.com/design/human-interface-guidelines/ornaments)
- [Eyes Guidelines](https://developer.apple.com/design/human-interface-guidelines/eyes)
- [Spatial Layout Guidelines](https://developer.apple.com/design/human-interface-guidelines/spatial-layout)
- [Playing Spatial Audio](https://developer.apple.com/documentation/visionOS/playing-spatial-audio-in-visionos)

### Design Tools

- Apple Design Resources for visionOS (Figma)
- Reality Composer Pro
- Xcode 16+ with visionOS 26 SDK

### Community Resources

- Q&A: Spatial design for visionOS (Apple Developer)
- Apple Developer Forums - visionOS section

---

## visionOS 26 Updates (2025)

### Key Features

**Liquid Glass Design**:
- Full adoption of Liquid Glass design language
- Translucent interfaces
- Fluid animations
- Unified aesthetic across Apple ecosystem

**Spatial Widgets**:
- Enhanced widget capabilities
- Spatial placement options

**Enhanced Personas**:
- Improved visual fidelity
- Better representation

**Spatial Scenes with AI-Generated Depth**:
- AI-powered depth generation
- Enhanced spatial content creation

**Enterprise APIs**:
- New capabilities for business applications

**Wide Field of View Support**:
- Native playback of 180°, 360° content
- Support for Insta360, GoPro, and Canon
- Apple Projected Media Profile (APMP)

### Technical Updates

- SwiftUI, UIKit, and AppKit APIs updated for Liquid Glass
- Enhanced PHASE framework capabilities
- Improved eye tracking and scroll features
- Advanced spatial audio implementation

---

## Conclusion

Designing for visionOS with Liquid Glass principles creates experiences that are:
- **Immersive** without being overwhelming
- **Comfortable** for extended use
- **Accessible** to all users
- **Beautiful** through depth and materiality
- **Consistent** with Apple's ecosystem

By following these guidelines, you'll create spatial experiences that feel natural, delightful, and uniquely suited to Apple Vision Pro.

---

*Last Updated: Based on visionOS 26 and WWDC 2025 announcements*
*For the most current guidelines, always consult the official Apple Developer Documentation*
