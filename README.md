# Aura Palm – Offline Palmistry App (iOS / SwiftUI)

A complete offline-first iOS palmistry application built using **SwiftUI**, **AVFoundation**, Apple's **Vision framework**, **Core Image**, **SwiftData**, and an offline rule engine.

Based on the **Offline Palmistry App – iOS / Xcode Technical Roadmap**.

---

## Key Features

1. **Vision Hand Pose Detection (`VNDetectHumanHandPoseRequest`)**
   - Tracks 21 anatomical hand landmarks in real-time.
   - Verifies hand side (Left vs Right), distance, upright orientation, and stability.
   - Real-time skeleton visualization with dynamic alignment guidance.

2. **Computer Vision & Line Ridge Tracing**
   - Landmark-guided ridge extraction across the palm.
   - Traces primary lines: **Life Line**, **Heart Line**, **Head Line**, and **Fate Line**.
   - Computes measurable characteristics: `length`, `curvature`, `crease depth`, and `continuity`.

3. **Offline Palmistry Rule Engine**
   - Rules mapped in `Resources/PalmistryRules.json` & `Resources/PalmistryMeanings.json`.
   - Distinct readings based on hand dominance:
     - **Right Hand**: Active / conscious potential, current trajectory, manifest choices.
     - **Left Hand**: Innate / subconscious blueprint, inherited gifts, natural instincts.
   - Analyzes planetary mounts (Jupiter, Saturn, Apollo, Mercury, Venus, Moon) and special markings (Mystic Cross, Writer's Fork, Protection Square, Triangles).

4. **Local Data & History (`SwiftData`)**
   - Persists past readings, vector coordinates, metrics, and captured palm snapshots offline.
   - Personal reflection notes editor.
   - Filter by hand and swipe-to-delete.

5. **Offline Daily Astrology & Cosmic Insight Module**
   - Calendar-based astronomical calculations for moon phases and daily planetary reflections.
   - 100% offline; works seamlessly in Airplane Mode.

6. **11 In-App Languages**
   - English, Hindi, Bengali, Marathi, Telugu, Tamil, Gujarati, Urdu (right-to-left), Kannada, Odia, and Malayalam.
   - Switch anytime from the 🌐 button on the Home screen; the whole app, including saved readings, updates instantly.
   - All strings live in `Resources/Localizable.xcstrings` (edit in Xcode's String Catalog editor). Readings are stored as translation keys, so history follows the selected language.

7. **Measured, Repeatable Readings**
   - Line length, depth, curve, continuity and breaks are measured from the creases in the photo (`ComputerVision/LineDetector.swift`); the same photo always gives the same reading.
   - Mount levels are estimated from measured hand proportions; markings are shown only when detected (Writer's Fork, breaks).
   - Lines that aren't visible are reported as such instead of being invented.

8. **Photo Import & Privacy**
   - Choose a palm photo from the library (no photo-library permission needed), including when camera access is denied.
   - First-launch entertainment notice, About & Privacy screen, and `Resources/PrivacyInfo.xcprivacy`.
   - `PRIVACY_POLICY.md` is ready to host; App Store Connect requires its URL.

9. **Hand Shape & Finger Analysis**
   - Palm shape, finger length, index vs ring finger, little-finger reach and thumb length, measured from the hand landmarks, with the hand element explained (Overview tab and saved history).

10. **Learn Palmistry**
   - Interactive palm map (tap any line or mount), seven short topics from Samudrika Shastra history to photo tips, and a 5-question quiz.

11. **Built-in iOS Simulator Support**
   - The simulator has no camera, so capture uses a generated palm with drawn creases (`Camera/SimulatedPalm.swift`) and runs it through the real detector.

---

## Xcode Setup Instructions

### 1. Create a New Xcode Project (or open existing)
1. Open **Xcode** on your Mac.
2. Select **File > New > Project...**
3. Choose **iOS > App**, then click **Next**.
4. Configure the project:
   - **Product Name**: `PalmistryApp`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `SwiftData`
5. Replace or drag the generated files from this repository into your Xcode project.

### 2. Configure `Info.plist` (Camera Permission)
Because this app scans palms with the camera, add the Camera Usage Description to your target's `Info.plist` or target settings:

- **Key**: `NSCameraUsageDescription` (`Privacy - Camera Usage Description`)
- **Value**: `"Aura Palm uses your camera to analyze palm lines and hand landmarks offline on your device."`

### 3. Target Requirements
- **Minimum iOS Version**: iOS 17.0+
- **Frameworks Used**: `SwiftUI`, `SwiftData`, `Vision`, `AVFoundation`, `CoreImage`

---

## Project Structure

```
PalmistryApp/
├── App/
│   ├── PalmistryApp.swift          # @main entry point & SwiftData container
│   └── AppEnvironment.swift        # Dependency injection container
├── Features/
│   ├── Home/                       # Cosmic landing screen & hand selector
│   ├── PalmScanner/                # Real-time camera scanner & guide overlay
│   ├── PalmAnalysis/               # Animated progress pulse during analysis
│   ├── PalmResult/                 # Result view with interactive vector overlays
│   ├── History/                    # SwiftData reading history & reflection notes
│   └── Astrology/                  # Offline daily planetary insight
├── Camera/
│   ├── CameraManager.swift         # AVCaptureSession & still photo capture
│   ├── CameraFrameProcessor.swift  # CMSampleBuffer converter
│   └── CameraPermission.swift      # Permission state checking
├── Vision/
│   ├── HandGeometry.swift          # Anatomical landmark calculations
│   ├── HandPoseDetector.swift      # VNDetectHumanHandPoseRequest wrapper
│   └── PalmRegionDetector.swift    # Palm bounding box & normalizer
├── ComputerVision/
│   ├── ImageQualityAnalyzer.swift  # Lighting, stability & distance checker
│   ├── PalmImageProcessor.swift    # CoreImage contrast & noise filters
│   ├── LineDetector.swift          # Landmark-guided candidate line tracing
│   └── EdgeDetector.swift          # Gradient edge filters
├── ML/
│   └── PalmLineClassifier.swift    # Classifies Life, Heart, Head, Fate lines
├── Palmistry/
│   ├── PalmistryEngine.swift       # Central engine coordinating analyzers
│   ├── LifeLineAnalyzer.swift
│   ├── HeartLineAnalyzer.swift
│   ├── HeadLineAnalyzer.swift
│   ├── FateLineAnalyzer.swift
│   ├── MountAnalyzer.swift
│   └── MarkingAnalyzer.swift
├── Data/
│   ├── Models/                     # SwiftData @Model & codable models
│   ├── Repositories/               # Data access protocols
│   └── PalmistryDatabase.swift     # ModelContainer initialization
├── Resources/
│   ├── PalmistryRules.json         # Rule engine threshold mappings
│   └── PalmistryMeanings.json      # Traditional palmistry interpretations
└── Utilities/
    ├── DesignSystem.swift          # Cosmic colors, gradients & modifiers
    ├── GeometryExtensions.swift    # Distance, curvature & bezier paths
    └── HapticManager.swift         # Tactile feedback generators
```
