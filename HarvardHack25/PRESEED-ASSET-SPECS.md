# PreSeed - visionOS App Icon & Asset Design Specification

## App Concept
**PreSeed** is a Vision Pro accessibility app that provides context-aware object reading and real-time assistance for visually impaired users, inspired by Be My Eyes but enhanced with spatial computing capabilities.

## Brand Identity

### Core Themes
- **Vision & Assistance**: Eye-based imagery representing both literal vision and the app's ability to "see" for users
- **Growth & Empowerment**: Seed/plant metaphor representing potential, growth, and independence
- **Connection**: Bridge between users and helpers, AI and human assistance
- **Clarity & Trust**: Clean, accessible design that conveys reliability

### Design Philosophy
Following visionOS Liquid Glass design language:
- Translucent, glass-like materials
- Depth and dimensionality
- Fluid, organic forms
- Light and shadow interplay
- Sophisticated yet approachable

---

## App Icon Specifications (visionOS Solid Image Stack)

### Technical Requirements
- **Format**: Three-layer solid image stack (Front, Middle, Back)
- **Dimensions**: 1024x1024px per layer
- **Color Space**: Display P3
- **File Format**: PNG with transparency
- **Naming**:
  - `Front.solidimagestacklayer/Content.png`
  - `Middle.solidimagestacklayer/Content.png`
  - `Back.solidimagestacklayer/Content.png`

---

## Layer 1: BACK (Background Foundation)

### Visual Description
A soft, organic gradient that evokes both natural growth and technological precision.

### Design Elements
- **Primary Shape**: Rounded square with subtle corner radius (matching visionOS aesthetic)
- **Gradient**: Radial gradient from center to edges
  - **Center**: Warm sage green (#8FBC94) - represents growth, life
  - **Edges**: Deep teal blue (#1A4D5C) - represents depth, technology, trust
- **Texture**: Very subtle glass-like texture overlay (10% opacity)
- **Lighting**: Soft ambient glow suggesting depth

### Color Palette (Back Layer)
```
Center: #8FBC94 (Sage Green)
Mid-tone: #4A7C7E (Teal)
Edge: #1A4D5C (Deep Teal)
Accent highlights: #A8D5BA (Light Mint) at 20% opacity
```

### Special Effects
- Subtle radial blur at edges (2-3px)
- Soft inner shadow suggesting depth into the glass
- Overall opacity: 90-95% to allow environmental pass-through

---

## Layer 2: MIDDLE (Atmospheric Glow)

### Visual Description
An ethereal glow layer that creates depth and suggests technological assistance - like gentle AI-powered illumination.

### Design Elements
- **Primary Shape**: Circular radial glow emanating from slightly off-center (60% from top)
- **Glow Effect**: Soft, diffused light rays that suggest vision assistance
- **Pattern**: 6-8 subtle light rays extending outward at varying angles
  - Ray opacity: 15-30%
  - Ray width: 40-60px with gradient edges
  - Ray length: Extends 70% across canvas

### Color Palette (Middle Layer)
```
Core glow: #FFFFFF (White) at 40% opacity
Ray color: #7DD3C0 (Aqua Mint) at 25% opacity
Accent: #FFE5B4 (Warm Peach) at 15% opacity - suggests warmth/humanity
```

### Special Effects
- Gaussian blur on rays (15-20px) for soft glow
- Radial gradient on main glow (100% center to 0% at edges)
- Slightly animated feeling (though static) - suggests responsiveness
- Overall layer opacity: 60-70%

---

## Layer 3: FRONT (Primary Icon Symbol)

### Visual Description
A sophisticated, modern icon combining an eye symbol with a sprouting seed - the core brand mark of PreSeed.

### Primary Symbol Design

#### Option A: Eye + Seedling Fusion (RECOMMENDED)
A stylized eye where the pupil transforms into a growing seedling:

**Eye Component:**
- Almond-shaped eye outline (400x280px centered)
- Smooth, rounded corners suggesting friendliness
- Eye outline: 12px stroke weight
- Color: White (#FFFFFF) with subtle gradient to light blue (#E8F5F7)

**Seedling Component:**
- Emerges from center of eye (pupil position)
- Two small leaves sprouting upward (60x80px total)
- Organic, flowing leaf shapes
- Gradient: Light green (#B8E6CC) to vibrant green (#4CAF50)

**Integration:**
- Leaves should appear to be "growing" from the eye's center
- Subtle connection lines suggesting neural/AI pathways
- Overall symbol sits in center of icon, occupying ~60% of canvas

#### Option B: Abstract Vision Symbol (ALTERNATIVE)
Geometric eye formed by layered arcs with central seed dot:
- Three concentric arcs forming stylized eye
- Central dot with small sprouting indicator
- More minimal, tech-forward aesthetic

### Color Palette (Front Layer)
```
Primary (Eye outline): #FFFFFF (White)
Gradient accent: #E8F5F7 (Ice Blue)
Seedling base: #B8E6CC (Mint)
Seedling tips: #4CAF50 (Vibrant Green)
Inner glow: #7DD3C0 (Aqua) at 30% opacity around symbol
```

### Special Effects
- **Outer glow**: 8px white glow around entire symbol (20% opacity)
- **Inner details**: Subtle line weight variation (10-14px) for depth
- **Highlights**: Small specular highlights on top-left of eye and leaf tips
- **Shadow**: Soft drop shadow (4px offset, 8px blur, 15% opacity)
- **Glass refraction**: Subtle lensing effect on the eye shape itself

### Typography (if needed for alternate layouts)
- Font: SF Pro Display (system font)
- Weight: Medium to Semibold
- NOT recommended for main icon - keep symbolic only

---

## Compositional Guidelines

### Overall Icon Assembly
When layers are stacked:
1. **Back layer**: Provides color foundation and depth
2. **Middle layer**: Creates atmospheric glow suggesting AI/tech assistance
3. **Front layer**: Crisp, clear symbol immediately readable

### Depth Hierarchy
- Front symbol should "float" ~40-50px in front of middle layer
- Middle glow should sit ~25-30px in front of back
- Total depth perception: ~80px of visual space

### Lighting Consistency
- Light source: Top-left (45° angle)
- All highlights and shadows should reinforce this direction
- Glass material catches and refracts this light

### Accessibility Considerations
- High contrast between front symbol and background
- Clear silhouette readable at small sizes
- No critical details thinner than 8px
- Passes WCAG AAA contrast requirements

---

## Additional Asset Specifications

### Accent Color
**Purpose**: Used throughout app for interactive elements, selections, highlights

**Color**: `#4CAF50` (Vibrant Green)
- Represents growth, confirmation, positive action
- Accessible on both light and dark backgrounds
- Aligns with seedling/growth brand theme

**File**: `AccentColor.colorset/Contents.json`
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "display-p3",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.314",
          "green" : "0.686",
          "red" : "0.298"
        }
      },
      "idiom" : "universal"
    }
  ]
}
```

### Supplementary Color Palette

**Primary Colors**:
- Sage Green: `#8FBC94` - Main brand color
- Deep Teal: `#1A4D5C` - Secondary, backgrounds
- Vibrant Green: `#4CAF50` - Accent, CTAs

**UI Colors**:
- Success: `#4CAF50` (Vibrant Green)
- Warning: `#FFB74D` (Warm Amber)
- Error: `#E57373` (Soft Red)
- Info: `#64B5F6` (Sky Blue)

**Glass Tints** (for Liquid Glass materials):
- Light Tint: `#FFFFFF` at 8% opacity
- Dark Tint: `#1A4D5C` at 12% opacity

---

## Icon Variations & States

### Default Icon
As described above - full color, all layers active.

### Dark Mode Variant
- Slightly increased glow on middle layer (+10% opacity)
- Front symbol gains subtle blue tint (#E8F5F7) at edges
- Back gradient shifts slightly cooler

### Notification Badge Area
- Top-right corner reserved for system notification badge
- Keep this area less visually busy in design

### Alternative Sizes
While visionOS scales automatically, ensure icon remains readable:
- **Large (App Store)**: 1024x1024px - full detail
- **Home Screen**: Automatically scaled - test at 256x256px preview
- **Settings/Spotlight**: Test legibility at 128x128px

---

## SF Symbols Custom Icon (Optional)

For in-app use, create a custom SF Symbol variant:

**Symbol Name**: `preseed.eye.leaf`

**Design**:
- Simplified version of front layer icon
- Monochrome line-art style
- Regular, Medium, Semibold, Bold weights
- Scales with Dynamic Type

**Use Cases**:
- Tab bar icons
- Toolbar buttons
- Settings menu items
- In-app navigation

---

## App Store Screenshot Backgrounds

**Suggested Background Treatments**:
1. **Gradient Background**: Use back layer gradient
2. **Blurred Environment**: Soft-focus real-world scene
3. **Glass Panels**: Floating glass UI elements on gradient

**Typography for Marketing**:
- Headline: SF Pro Display, Bold, 72pt
- Tagline: SF Pro, Medium, 24pt
- Body: SF Pro, Regular, 18pt

---

## Design Implementation Checklist

### For Figma/Design Tool:
- [ ] Create 1024x1024px artboards for each layer
- [ ] Set color space to Display P3
- [ ] Use vector shapes for scalability
- [ ] Apply gradients with proper angle/positioning
- [ ] Add blur and glow effects as specified
- [ ] Export as PNG with transparency
- [ ] Test layer stacking in visionOS simulator

### For AI Image Generation Prompts:

**Back Layer Prompt**:
```
A rounded square gradient background for a visionOS app icon, radial gradient from sage green center (#8FBC94) to deep teal edges (#1A4D5C), subtle glass texture, soft ambient lighting, translucent material, Liquid Glass aesthetic, 1024x1024px, Display P3 color space
```

**Middle Layer Prompt**:
```
Ethereal glow layer for visionOS icon, circular radial glow with 6-8 soft light rays emanating outward, aqua mint color (#7DD3C0), diffused and blurred, atmospheric, technological, transparent background, 1024x1024px, 60% overall opacity
```

**Front Layer Prompt**:
```
Minimalist icon combining stylized eye outline with sprouting seedling emerging from center, white eye shape with ice blue gradient, vibrant green leaves, clean lines, modern, accessible, glass refraction effect, outer glow, transparent background, visionOS Liquid Glass style, 1024x1024px
```

### Quality Assurance:
- [ ] Icon is distinctive and memorable
- [ ] Readable at all sizes (1024px down to 128px)
- [ ] Aligns with visionOS Human Interface Guidelines
- [ ] Reflects app functionality (vision + assistance + growth)
- [ ] Works in both light and dark environments
- [ ] Passes accessibility contrast checks
- [ ] Looks professional alongside other visionOS apps

---

## Brand Application Examples

### Launch Screen
- Full app icon centered
- "PreSeed" wordmark below (SF Pro Display Medium)
- Gradient background matching icon back layer

### Loading States
- Animated version of middle layer glow pulsing
- Seedling leaves subtle sway animation

### Empty States
- Simplified icon symbol (front layer only)
- Friendly, encouraging messaging

### Success Confirmations
- Icon with enhanced glow
- Vibrant green accent highlights

---

## File Organization in Assets.xcassets

```
Assets.xcassets/
├── AppIcon.solidimagestack/
│   ├── Front.solidimagestacklayer/
│   │   └── Content.png (1024x1024px)
│   ├── Middle.solidimagestacklayer/
│   │   └── Content.png (1024x1024px)
│   ├── Back.solidimagestacklayer/
│   │   └── Content.png (1024x1024px)
│   └── Contents.json
├── AccentColor.colorset/
├── BrandColors.colorset/ (optional)
├── LaunchImage.imageset/ (optional)
└── CustomSymbols.symbolset/ (optional)
```

---

## References & Inspiration

### Design Inspiration:
- Be My Eyes app icon (accessibility focus)
- Apple Health icon (growth/wellness theme)
- Vision Pro native apps (Liquid Glass aesthetic)
- Seedlang, Duolingo (friendly, growth-oriented)

### visionOS Design Resources:
- Apple Design Resources (Figma templates)
- HIG: Liquid Glass documentation
- HIG: App icons for visionOS
- WWDC 2025: Meet Liquid Glass

---

## Design Rationale

**Why Eye + Seedling?**
- **Eye**: Represents vision, sight, awareness - the core problem space
- **Seedling**: Represents growth, potential, empowerment - the solution
- **Combination**: Vision assistance that helps users grow and flourish independently

**Why These Colors?**
- **Green**: Universal symbol for growth, go/safe, nature, life
- **Teal/Blue**: Trust, technology, reliability, calm
- **White**: Clarity, simplicity, accessibility, light

**Why Liquid Glass Aesthetic?**
- Platform-native design language
- Conveys sophistication and modernity
- Depth and translucency suggest dimensional awareness
- Aligns with Vision Pro's premium positioning

---

## Next Steps

1. **Create icon layers** in Figma or your preferred design tool
2. **Export PNGs** at exactly 1024x1024px per layer
3. **Place files** in respective `.solidimagestacklayer` folders
4. **Test in Xcode** with visionOS simulator
5. **Iterate** based on how it looks in actual glass material
6. **Prepare App Store assets** (screenshots, previews, marketing)

---

**Version**: 1.0
**Last Updated**: October 2025
**App**: PreSeed for visionOS
**Project**: HackHarvard 2025
