# HIG Audit — Wake Capture iOS

## Application Overview

Wake Capture is a single-purpose audio recording app designed for capturing thoughts immediately upon waking. The user "arms" the app before sleep; upon waking, they trigger a recording via the Lock Screen, Control Center, or in-app button. Recordings are saved locally and browsable in a history list.

## Architecture Overview

| Attribute | Value |
|---|---|
| Framework | Pure SwiftUI |
| Min deployment target | iOS 18.0 |
| Swift version | 6.0 |
| Device families | iPhone only (`TARGETED_DEVICE_FAMILY: "1"`) |
| Orientations | Default (portrait assumed; no explicit lock) |
| Navigation | `NavigationStack` (single stack) |
| State management | `@Observable` (`CaptureCoordinator`), `@AppStorage`, `@Environment`, SwiftData `@Query` |
| Persistence | SwiftData (`CaptureRecord`), `UserDefaults`, file system (`RecordingFileStore`) |
| Design system / theme | None — ad-hoc colors, sizes, spacing |
| Localization | None — all strings hardcoded in English, no `.strings`/`.xcstrings` files, `STRING_CATALOG_GENERATE_SYMBOLS: YES` set but no catalogs exist |
| Accessibility | No explicit accessibility labels, hints, traits, or modifiers anywhere in the codebase |
| Custom components | `CaptureRow`, `PlayerDelegate` |
| Custom controls | Large circular stop button (RecordingView), custom armed/disarmed toggle layout |
| Custom gestures | None |
| Third-party UI deps | None |
| Reusable UI primitives | None |
| Test infrastructure | XCTest unit tests (CaptureCoordinatorTests, AutoDisarmManagerTests) with mocks. No UI tests. |
| Extensions | WidgetKit Control Widget, Live Activity |

## Screen Inventory

### 1. Onboarding (OnboardingView)

- **Purpose**: First-run walkthrough (welcome, mic permission, lock screen control guidance)
- **Primary task**: Grant microphone permission
- **Primary action**: "Next" / "Grant Access" / "Get Started" buttons
- **Secondary actions**: "Skip for now" on mic page
- **Navigation**: Paged `TabView` with swipe
- **Controls**: `Button` (.borderedProminent)
- **Typography**: `.largeTitle.bold()`, `.title.bold()`, `.body`, `.callout`
- **Colors**: `.indigo`, `.green`, `.blue` (hardcoded), `.secondary`
- **Spacing**: `spacing: 24`, `padding(.horizontal, 40)`, `padding(.horizontal, 32)`, `Spacer().frame(height: 60)`
- **Icons**: SF Symbols (`moon.zzz.fill`, `mic.badge.plus`, `lock.shield`)
- **Sheets/Alerts**: None
- **Loading states**: None
- **Empty states**: N/A
- **Error states**: None (permission denial silently advances)
- **Accessibility labels**: None
- **Dynamic Type**: Uses semantic text styles — will scale
- **Dark Mode**: System colors will adapt; hardcoded `.indigo`/`.green`/`.blue` may not have ideal contrast
- **Safe area**: Content is vertically centered with Spacers; no explicit safe-area handling
- **Orientation**: No lock — landscape would distort layout

### 2. Home Screen (HomeView in ContentView)

- **Purpose**: Primary hub — arm/disarm, start capture, navigate to history/settings
- **Primary task**: Arm the app, then start a capture
- **Primary action**: "Arm Wake Capture" / "Disarm" button
- **Secondary actions**: "Start Capture" (conditional), navigation to History, navigation to Settings
- **Navigation**: `NavigationStack` with `.inline` title display
- **Controls**: `Button` (.borderedProminent), `NavigationLink`
- **Typography**: `.system(size: 80)` (icon), `.title2.semibold`, `.subheadline`, `.title3.medium`, `.callout`
- **Colors**: `.green`, `.gray`, `.secondary`, `.red` (all hardcoded tints)
- **Spacing**: `spacing: 40`, `spacing: 12`, `padding(.vertical, 16)`, `padding(.horizontal, 40)`, `padding(.bottom, 8)`, `padding(.bottom, 32)`
- **Icons**: SF Symbols (`mic.circle.fill`, `mic.circle`, `record.circle`, `list.bullet`, `gear`)
- **Sheets/Alerts**: None
- **Loading states**: None (starting state handled by ContentView switching to RecordingView)
- **Empty states**: N/A
- **Error states**: Red error text from `coordinator.lastError`
- **Accessibility labels**: None
- **Dynamic Type**: `.system(size: 80)` icon won't scale with Dynamic Type
- **Dark Mode**: `.green`, `.gray`, `.red` tints are adaptive; `.secondary` is semantic
- **Safe area**: Full-screen `VStack` with Spacers — reasonable
- **Orientation**: No lock; VStack layout would compress awkwardly in landscape

### 3. Recording Screen (RecordingView)

- **Purpose**: Active recording display with stop control
- **Primary task**: Monitor recording and stop when done
- **Primary action**: "STOP" button (large red circle)
- **Secondary actions**: None
- **Navigation**: Replaces entire NavigationStack via ContentView state switch
- **Controls**: Custom circular stop button (not a standard control)
- **Typography**: `.system(size: 20, weight: .bold, design: .monospaced)`, `.system(size: 72, weight: .light, design: .monospaced)`, `.system(size: 24, weight: .bold)` — all fixed sizes
- **Colors**: `.red`, `.white`, `.black` background — all hardcoded
- **Spacing**: `spacing: 48`, `frame(width: 140, height: 140)`
- **Icons**: None (uses text + shapes)
- **Gestures**: None
- **Sheets/Alerts**: None
- **Loading states**: Opacity changes during `.starting`/`.stopping`
- **Empty states**: N/A
- **Error states**: None on this screen
- **Accessibility labels**: None — the stop button has no accessibility label
- **Dynamic Type**: All fixed font sizes — does not support Dynamic Type
- **Dark Mode**: Forces `.preferredColorScheme(.dark)` — always dark
- **Safe area**: `.frame(maxWidth: .infinity, maxHeight: .infinity)` with `.background(.black)`
- **Orientation**: Would work but button is fixed-size

### 4. Settings Screen (SettingsView)

- **Purpose**: Configure recording parameters and auto-disarm
- **Primary task**: Adjust recording limits
- **Primary action**: Slider adjustments
- **Controls**: `Form`, `Slider`, `Picker`, `LabeledContent`
- **Typography**: Default Form typography
- **Colors**: System default
- **Spacing**: Default Form spacing
- **Icons**: None
- **Sheets/Alerts**: None
- **Loading states**: None
- **Empty states**: N/A
- **Error states**: None
- **Accessibility labels**: None
- **Dynamic Type**: Form elements scale automatically
- **Dark Mode**: Form adapts automatically
- **Safe area**: Form handles safe areas

### 5. Capture History (CaptureHistoryView)

- **Purpose**: Browse and delete past recordings
- **Primary task**: Review past captures
- **Primary action**: Tap to view detail
- **Secondary actions**: Swipe-to-delete
- **Navigation**: `NavigationLink` to detail
- **Controls**: `List`, `ContentUnavailableView` (empty state)
- **Typography**: `.body.medium`, `.caption`
- **Colors**: `.secondary`
- **Icons**: SF Symbols (`clock`, `checkmark.circle`, `exclamationmark.triangle`, `xmark.circle`, `questionmark.circle`, `waveform`)
- **Loading states**: None
- **Empty states**: `ContentUnavailableView` — good use of native component
- **Error states**: None
- **Accessibility labels**: None
- **Dynamic Type**: Semantic styles will scale
- **Dark Mode**: Semantic colors adapt

### 6. Capture Detail (CaptureDetailView)

- **Purpose**: View recording metadata and play audio
- **Primary task**: Play back a recording
- **Primary action**: Play/stop button
- **Controls**: `List`, `LabeledContent`, `Button`
- **Typography**: Default List/Form typography
- **Colors**: System default
- **Icons**: SF Symbols (`stop.fill`, `play.fill`)
- **Loading states**: None
- **Empty states**: None (button disabled if file missing)
- **Error states**: Silent failure on playback error (catch block just sets `isPlaying = false`)
- **Accessibility labels**: None

### 7. Live Activity (CaptureActivityView)

- **Purpose**: Lock screen and Dynamic Island recording status
- **Controls**: Native ActivityKit, `DynamicIsland`, intent-based stop button
- **Typography**: `.system(size: 28)`, `.system(size: 32)` — fixed sizes; `.caption.monospacedDigit()`, `.subheadline.weight(.semibold)`, `.headline`
- **Colors**: `.red`, `.white`
- **Icons**: SF Symbols (`mic.fill`, `stop.fill`)

### 8. Control Widget (WakeCaptureControl)

- **Purpose**: Lock Screen / Control Center quick-start button
- **Controls**: Native `ControlWidget` with `ControlWidgetButton`
- **Icons**: SF Symbols (`mic.circle.fill`)

## Component Inventory

### CaptureRow
- **Purpose**: List row for a capture record
- **Native equivalent**: No exact equivalent, but follows standard List row pattern
- **Implementation**: VStack with title + HStack metadata
- **Accessibility**: No labels or traits

### PlayerDelegate (private class in CaptureDetailView)
- **Purpose**: AVAudioPlayerDelegate bridge
- **Native equivalent**: N/A (UIKit bridge requirement)
- **Implementation**: NSObject subclass with closure callback

---

## HIG Findings

### P0 — Critical

#### P0-01: No accessibility labels anywhere
- **Screen**: All screens
- **Current**: Zero `.accessibilityLabel()`, `.accessibilityHint()`, or `.accessibilityValue()` modifiers in the entire codebase
- **HIG**: [Accessibility — VoiceOver](https://developer.apple.com/design/human-interface-guidelines/accessibility) — all interactive elements must be accessible. The stop button on RecordingView is a custom shape with no label — completely invisible to VoiceOver.
- **Files**: All UI/*.swift, CaptureActivityView.swift
- **Risk**: App is unusable for VoiceOver users

#### P0-02: RecordingView fixed font sizes ignore Dynamic Type
- **Screen**: RecordingView
- **Current**: `.system(size: 20)`, `.system(size: 72)`, `.system(size: 24)` — fixed point sizes
- **HIG**: [Typography — Dynamic Type](https://developer.apple.com/design/human-interface-guidelines/typography) — text must scale with the user's preferred content size
- **Files**: RecordingView.swift
- **Risk**: Text unreadable at larger accessibility sizes

#### P0-03: Stop button touch target on RecordingView may be adequate (140pt) but has no accessibility representation
- **Screen**: RecordingView
- **Current**: 140×140pt circle button with no `.accessibilityLabel`
- **HIG**: [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) — all controls need accessible names
- **Files**: RecordingView.swift

### P1 — High

#### P1-01: Home screen uses center-stacked VStack layout instead of List/Form for navigation items
- **Screen**: HomeView
- **Current**: NavigationLinks to History and Settings are plain links at the bottom of a VStack with ad-hoc padding
- **HIG**: [Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables) — navigation destinations typically appear in Lists; this layout doesn't match iOS conventions
- **Files**: ContentView.swift
- **Risk**: Medium — functional but unfamiliar

#### P1-02: Error display is easily missed
- **Screen**: HomeView
- **Current**: Red text displayed inline, can scroll off screen, no alert or prominent treatment
- **HIG**: [Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts) — errors requiring user attention should use alerts or prominent in-context feedback
- **Files**: ContentView.swift
- **Risk**: Users may not see errors

#### P1-03: RecordingView forces dark color scheme unconditionally
- **Screen**: RecordingView
- **Current**: `.preferredColorScheme(.dark)` and `.background(.black)` hardcoded
- **HIG**: [Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode) — apps should respect the user's system appearance setting. Overriding it is acceptable only for specific content like media playback.
- **Files**: RecordingView.swift
- **Risk**: Jarring transition, disrespects user preference

#### P1-04: Onboarding page indicators use deprecated/non-standard pattern
- **Screen**: OnboardingView
- **Current**: `TabView` with `.tabViewStyle(.page)` for onboarding
- **HIG**: While paged TabViews are a known pattern, there's no progress indication beyond dots, no way to go back explicitly, and the page indicator style may not survive iOS 26 design changes gracefully
- **Files**: OnboardingView.swift
- **Risk**: Low-medium

#### P1-05: No confirmation for destructive delete action
- **Screen**: CaptureHistoryView
- **Current**: Swipe-to-delete immediately deletes with no confirmation
- **HIG**: [Destructive actions](https://developer.apple.com/design/human-interface-guidelines/managing-data-entry#Destructive-actions) — destructive actions should confirm, especially for user-generated content that cannot be recovered
- **Files**: CaptureHistoryView.swift
- **Risk**: Accidental data loss

#### P1-06: Playback error silently swallowed
- **Screen**: CaptureDetailView
- **Current**: `catch { isPlaying = false }` — no user feedback on failure
- **HIG**: [Feedback](https://developer.apple.com/design/human-interface-guidelines/playing-audio) — the system should acknowledge user actions and report errors
- **Files**: CaptureDetailView.swift

#### P1-07: Home screen icon uses fixed `.system(size: 80)` — ignores Dynamic Type
- **Screen**: HomeView
- **Current**: `.font(.system(size: 80))` for the mic icon
- **HIG**: [Typography](https://developer.apple.com/design/human-interface-guidelines/typography) — prefer scalable text styles
- **Files**: ContentView.swift

### P2 — Medium

#### P2-01: No semantic/adaptive colors — hardcoded `.green`, `.red`, `.gray`, `.black`, `.white`, `.indigo`, `.blue`
- **Screen**: Multiple
- **Current**: Raw color literals throughout
- **HIG**: [Color](https://developer.apple.com/design/human-interface-guidelines/color) — use semantic system colors that adapt to appearance modes and accessibility settings (Increase Contrast)
- **Files**: ContentView.swift, RecordingView.swift, OnboardingView.swift

#### P2-02: No Increase Contrast support
- **Screen**: All
- **Current**: No `.accessibilityShowButtonShapes`, no contrast-aware color choices
- **HIG**: [Accessibility — Increase Contrast](https://developer.apple.com/design/human-interface-guidelines/accessibility) — apps should respond to the Increase Contrast accessibility setting
- **Files**: All UI files

#### P2-03: Settings uses Slider where Stepper or direct input might be more accessible
- **Screen**: SettingsView
- **Current**: `Slider` for max recording (1-30 min) and silence timeout (10-120s)
- **HIG**: [Sliders](https://developer.apple.com/design/human-interface-guidelines/sliders) — sliders work for continuous values but these are discrete values with step increments. Sliders are also harder for VoiceOver users. `Stepper` or `Picker` may be more appropriate.
- **Files**: SettingsView.swift

#### P2-04: Onboarding hardcoded icon colors don't adapt to Increase Contrast
- **Screen**: OnboardingView
- **Current**: `.foregroundStyle(.indigo)`, `.foregroundStyle(.green)`, `.foregroundStyle(.blue)`
- **HIG**: [Color](https://developer.apple.com/design/human-interface-guidelines/color) — decorative colors should still meet contrast requirements
- **Files**: OnboardingView.swift

#### P2-05: Navigation links at bottom of Home look like standalone text links, not standard iOS navigation
- **Screen**: HomeView
- **Current**: Two `NavigationLink` items with `Label` and no list context, ad-hoc bottom padding
- **HIG**: [Navigation](https://developer.apple.com/design/human-interface-guidelines/navigation) — navigation destinations are typically in Lists or toolbars
- **Files**: ContentView.swift

#### P2-06: No Reduce Motion support
- **Screen**: RecordingView, HomeView
- **Current**: Pulsing red dot animation, symbol effect replace transition — no check for `accessibilityReduceMotion`
- **HIG**: [Motion — Reduce Motion](https://developer.apple.com/design/human-interface-guidelines/motion) — respect the Reduce Motion preference
- **Files**: RecordingView.swift, ContentView.swift

#### P2-07: CaptureRow vertical padding is manual (`padding(.vertical, 4)`) instead of relying on List defaults
- **Screen**: CaptureHistoryView
- **Current**: Manual padding on rows
- **HIG**: [Lists](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables) — default List row spacing is well-tuned for touch targets
- **Files**: CaptureHistoryView.swift

#### P2-08: Live Activity uses fixed font sizes
- **Screen**: CaptureActivityView
- **Current**: `.system(size: 28)`, `.system(size: 32)` — fixed sizes
- **HIG**: Live Activity design guidelines recommend using semantic text styles where possible
- **Files**: CaptureActivityView.swift

#### P2-09: No asset catalog — no app icon, no color assets, no image assets
- **Current**: `ASSETCATALOG_COMPILER_APPICON_NAME: "AppIcon"` is set but no `.xcassets` directory exists
- **HIG**: [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons) — every app needs an icon
- **Files**: project.yml
- **Risk**: App will use default placeholder icon

### P3 — Polish

#### P3-01: Onboarding buttons have inconsistent sizing (not full-width like Home screen buttons)
- **Screen**: OnboardingView
- **Current**: Default `.borderedProminent` button width (content-sized)
- **Files**: OnboardingView.swift

#### P3-02: No haptic feedback on arm/disarm toggle
- **Screen**: HomeView
- **Current**: Haptics only on start/stop recording
- **HIG**: [Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics) — provide haptic feedback for significant state changes
- **Files**: ContentView.swift

#### P3-03: "RECORDING" and "STOP" text is all-caps
- **Screen**: RecordingView
- **Current**: All-caps hardcoded strings
- **HIG**: [Typography](https://developer.apple.com/design/human-interface-guidelines/typography) — prefer sentence case; use `.textCase(.uppercase)` if uppercase is intentional
- **Files**: RecordingView.swift

#### P3-04: ContentUnavailableView in CaptureHistoryView is inside the List
- **Screen**: CaptureHistoryView
- **Current**: Empty state view rendered as a List row
- **HIG**: `ContentUnavailableView` should typically replace the List, not be a child of it
- **Files**: CaptureHistoryView.swift

#### P3-05: No transition animation between armed/disarmed states on Home
- **Screen**: HomeView
- **Current**: The "Start Capture" button appears/disappears with no animation
- **Files**: ContentView.swift
