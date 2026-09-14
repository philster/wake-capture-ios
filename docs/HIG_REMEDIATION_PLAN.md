# HIG Remediation Plan — Wake Capture iOS

## Implementation Order

Changes are grouped by severity, then by dependency. Each group should be implemented and verified before moving to the next.

---

## Group 1: P0 — Critical Accessibility

### P0-01: Add accessibility labels, hints, and traits to all interactive elements

| Field | Value |
|---|---|
| **Issue ID** | P0-01 |
| **Screen/Component** | All screens |
| **Current** | Zero accessibility modifiers in the codebase |
| **HIG Guidance** | All interactive controls must have accessible names. Custom controls need explicit labels. State changes need accessibility announcements. |
| **Severity** | P0 |
| **Recommended change** | Add `.accessibilityLabel()`, `.accessibilityHint()`, `.accessibilityValue()`, and `.accessibilityAddTraits()` to every interactive element. Key targets: RecordingView stop button, HomeView arm/disarm button, HomeView start capture button, onboarding buttons, CaptureDetailView play button, CaptureRow, navigation links. Add `.accessibilityElement(children:)` to group related content where appropriate. |
| **Files** | ContentView.swift, RecordingView.swift, OnboardingView.swift, CaptureHistoryView.swift, CaptureDetailView.swift, SettingsView.swift |
| **Risk** | Low — additive change |
| **Dependencies** | None |
| **Validation** | Enable VoiceOver in simulator; navigate all screens; verify every control is announced with meaningful label and role |

### P0-02: Replace fixed font sizes in RecordingView with scalable alternatives

| Field | Value |
|---|---|
| **Issue ID** | P0-02 |
| **Screen/Component** | RecordingView |
| **Current** | `.system(size: 20)`, `.system(size: 72)`, `.system(size: 24)` |
| **HIG Guidance** | Use Dynamic Type text styles; text must remain readable at all accessibility sizes |
| **Severity** | P0 |
| **Recommended change** | Replace fixed sizes with semantic styles: "RECORDING" → `.headline`, elapsed time → `.largeTitle` with `.dynamicTypeSize(...)` range to prevent extreme scaling, "STOP" → `.title2.bold()`. Use `@ScaledMetric` for the stop button dimensions. |
| **Files** | RecordingView.swift |
| **Risk** | Low — visual change only, layout may need testing at extreme sizes |
| **Dependencies** | None |
| **Validation** | Test at default, largest standard, and largest accessibility type sizes |

### P0-03: Make RecordingView stop button accessible

| Field | Value |
|---|---|
| **Issue ID** | P0-03 |
| **Screen/Component** | RecordingView |
| **Current** | Custom circle button with no accessibility representation |
| **HIG Guidance** | All controls must be accessible |
| **Severity** | P0 |
| **Recommended change** | Add `.accessibilityLabel("Stop recording")` and `.accessibilityAddTraits(.isButton)` |
| **Files** | RecordingView.swift |
| **Risk** | None |
| **Dependencies** | Part of P0-01 |
| **Validation** | VoiceOver announces "Stop recording, button" |

---

## Group 2: P1 — Platform Conventions

### P1-01: Restructure Home screen navigation

| Field | Value |
|---|---|
| **Issue ID** | P1-01 + P2-05 |
| **Screen/Component** | HomeView |
| **Current** | NavigationLinks at bottom of VStack with ad-hoc padding |
| **HIG Guidance** | Navigation destinations belong in standard navigation patterns (toolbar, list) |
| **Severity** | P1 |
| **Recommended change** | Move Settings to a toolbar button (`.toolbar { ... }`). Move History to a toolbar button or keep as a more prominent navigation element. This is a single-purpose app — the home screen should focus on the arm/capture flow. |
| **Files** | ContentView.swift |
| **Risk** | Medium — changes visual layout |
| **Dependencies** | None |
| **Validation** | Manual testing; verify navigation works, back buttons work |

### P1-02: Surface errors via alerts instead of inline text

| Field | Value |
|---|---|
| **Issue ID** | P1-02 |
| **Screen/Component** | HomeView |
| **Current** | Red text inline in VStack |
| **HIG Guidance** | Errors that prevent core actions should use alerts |
| **Severity** | P1 |
| **Recommended change** | Use `.alert()` modifier triggered by `coordinator.lastError != nil`. Present the error message with a dismiss action. Clear `lastError` on dismiss. |
| **Files** | ContentView.swift |
| **Risk** | Low |
| **Dependencies** | None |
| **Validation** | Trigger error states (deny mic permission); verify alert appears |

### P1-03: Respect system color scheme in RecordingView

| Field | Value |
|---|---|
| **Issue ID** | P1-03 |
| **Screen/Component** | RecordingView |
| **Current** | Forces `.preferredColorScheme(.dark)`, hardcoded `.black` background and `.white` text |
| **HIG Guidance** | Respect user's appearance setting |
| **Severity** | P1 |
| **Recommended change** | Remove `.preferredColorScheme(.dark)`. Use semantic background color (`.background(Color(.systemBackground))`). Use semantic text colors. Keep `.red` accent as it's contextually appropriate for recording state. |
| **Files** | RecordingView.swift |
| **Risk** | Medium — visual change |
| **Dependencies** | None |
| **Validation** | Test in both Light and Dark Mode |

### P1-05: Add delete confirmation for captures

| Field | Value |
|---|---|
| **Issue ID** | P1-05 |
| **Screen/Component** | CaptureHistoryView |
| **Current** | Swipe-to-delete with no confirmation |
| **HIG Guidance** | Destructive actions on user content should confirm |
| **Severity** | P1 |
| **Recommended change** | Add `.confirmationDialog` or `.alert` before deletion. Alternative: the native swipe-to-delete with a red "Delete" button is a well-understood iOS pattern and may be sufficient without additional confirmation — but since recordings are unrecoverable, adding confirmation is prudent. |
| **Files** | CaptureHistoryView.swift |
| **Risk** | Low |
| **Dependencies** | None |
| **Validation** | Swipe to delete; verify confirmation appears |

### P1-06: Show error on playback failure

| Field | Value |
|---|---|
| **Issue ID** | P1-06 |
| **Screen/Component** | CaptureDetailView |
| **Current** | Error silently swallowed |
| **HIG Guidance** | Report errors to users |
| **Severity** | P1 |
| **Recommended change** | Add `@State private var playbackError: String?` and `.alert()` to show playback failure |
| **Files** | CaptureDetailView.swift |
| **Risk** | Low |
| **Dependencies** | None |
| **Validation** | Corrupt or delete a recording file; attempt playback |

### P1-07: Replace fixed icon size on Home screen

| Field | Value |
|---|---|
| **Issue ID** | P1-07 |
| **Screen/Component** | HomeView |
| **Current** | `.font(.system(size: 80))` |
| **HIG Guidance** | Use scalable sizes |
| **Severity** | P1 |
| **Recommended change** | Use `@ScaledMetric` for the icon size, or use a large semantic text style |
| **Files** | ContentView.swift |
| **Risk** | Low |
| **Dependencies** | None |
| **Validation** | Test Dynamic Type sizes |

---

## Group 3: P2 — Visual System

### P2-01: Replace hardcoded colors with semantic colors

| Field | Value |
|---|---|
| **Issue ID** | P2-01 |
| **Screen/Component** | Multiple |
| **Current** | `.green`, `.red`, `.gray`, `.black`, `.white`, `.indigo`, `.blue` |
| **HIG Guidance** | Use system semantic colors |
| **Severity** | P2 |
| **Recommended change** | `.black` → `Color(.systemBackground)`, `.white` → `Color(.label)`. Accent colors (`.green`, `.red`) are fine as tints — they're already adaptive SwiftUI colors. `.indigo`/`.blue` onboarding decorative colors are acceptable. Main fix is RecordingView's hardcoded black/white. |
| **Files** | RecordingView.swift primarily |
| **Risk** | Low |
| **Dependencies** | P1-03 |
| **Validation** | Test Light/Dark mode, Increase Contrast |

### P2-03: Replace Sliders with Pickers in Settings

| Field | Value |
|---|---|
| **Issue ID** | P2-03 |
| **Screen/Component** | SettingsView |
| **Current** | Slider for discrete values |
| **HIG Guidance** | Sliders for continuous, pickers/steppers for discrete values; sliders are hard for VoiceOver |
| **Severity** | P2 |
| **Recommended change** | Replace max recording slider with a `Picker` showing preset values (1, 2, 5, 10, 15, 30 min). Replace silence timeout slider with a `Picker` showing preset values (10, 15, 30, 45, 60, 90, 120s). |
| **Files** | SettingsView.swift |
| **Risk** | Low |
| **Dependencies** | None |
| **Validation** | VoiceOver navigation; verify values persist |

### P2-06: Add Reduce Motion support

| Field | Value |
|---|---|
| **Issue ID** | P2-06 |
| **Screen/Component** | RecordingView, HomeView |
| **Current** | Pulsing animation, symbol effects with no Reduce Motion check |
| **HIG Guidance** | Respect `accessibilityReduceMotion` |
| **Severity** | P2 |
| **Recommended change** | Check `@Environment(\.accessibilityReduceMotion)` and disable pulsing dot animation and `.contentTransition(.symbolEffect)` when enabled |
| **Files** | RecordingView.swift, ContentView.swift |
| **Risk** | Low |
| **Dependencies** | None |
| **Validation** | Enable Reduce Motion in settings; verify no pulsing/animated transitions |

### P2-07: Remove manual CaptureRow padding

| Field | Value |
|---|---|
| **Issue ID** | P2-07 |
| **Screen/Component** | CaptureHistoryView |
| **Current** | `.padding(.vertical, 4)` |
| **HIG Guidance** | Trust List's built-in spacing |
| **Severity** | P2 |
| **Recommended change** | Remove `.padding(.vertical, 4)` from CaptureRow |
| **Files** | CaptureHistoryView.swift |
| **Risk** | None |
| **Dependencies** | None |
| **Validation** | Visual check |

### P2-09: Create asset catalog with AppIcon placeholder

| Field | Value |
|---|---|
| **Issue ID** | P2-09 |
| **Screen/Component** | Project |
| **Current** | No .xcassets directory |
| **HIG Guidance** | Every app needs an icon |
| **Severity** | P2 |
| **Recommended change** | Create `WakeCapture/Assets.xcassets` with `AppIcon.appiconset` and `AccentColor` colorset. Note: actual icon design is out of scope — create the structure with placeholder. |
| **Files** | project.yml, new Assets.xcassets |
| **Risk** | Low |
| **Dependencies** | None |
| **Validation** | Build succeeds; icon appears in simulator |

---

## Group 4: P3 — Polish

### P3-01: Consistent button sizing in onboarding
### P3-02: Add haptic on arm/disarm
### P3-03: Use `.textCase(.uppercase)` instead of hardcoded caps
### P3-04: Move ContentUnavailableView outside List
### P3-05: Add animation to Start Capture button appearance

These are low-priority refinements to address after P0-P2 are resolved.

---

## Risk Summary

| Risk | Mitigation |
|---|---|
| Accessibility labels may be verbose or unclear | Test with VoiceOver; iterate on wording |
| RecordingView visual change (removing forced dark) | May need design review; the dark recording screen is a deliberate aesthetic choice — could be preserved with semantic colors instead |
| Settings Picker change | Ensure selected values map correctly to existing settings |
| Layout changes at extreme Dynamic Type sizes | Test at all sizes; use `.dynamicTypeSize(...)` range to cap extreme scaling where needed |

## Dependencies

```
P0-01 (accessibility labels) — no dependencies, do first
P0-02 (Dynamic Type) — no dependencies
P0-03 (stop button a11y) — subset of P0-01
P1-03 (color scheme) → P2-01 (semantic colors) — do P1-03 first
All other items are independent
```
