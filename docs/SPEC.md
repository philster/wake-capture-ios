# Technical Specification — Wake Capture for iOS

## 0. Purpose

Build an iOS-first, audio-only "Wake Capture" application optimized for a user who is half-awake during the night or immediately after waking.

Primary interaction:

1. User arms Wake Capture before sleep.
2. Device is locked.
3. User performs one deliberate system-level Capture action.
4. Audio recording begins immediately.
5. User speaks.
6. User stops capture with another deliberate action, or an inactivity timeout ends it.
7. Raw audio is durably saved locally.
8. Transcription/AI processing happens later and must never be required for capture success.

Do NOT implement video capture in this version.

The app must use Apple's normal permission, privacy-indicator, lock-screen, and system-control mechanisms. Never bypass authentication, microphone permissions, recording indicators, or other OS security boundaries.

---

## 1. Platform / implementation target

- Language: Swift 6.0 (strict concurrency)
- UI: SwiftUI
- Minimum deployment target: iOS 18.0 (required for WidgetKit Controls and AudioRecordingIntent)
- Xcode: 26.3 or later
- Architecture: native iOS application; do not use React Native for the system integration layer.
- Project generation: XcodeGen (`project.yml` is the source of truth; `.xcodeproj` is not checked in)
- Frameworks:
  - SwiftUI
  - AVFoundation
  - AppIntents
  - WidgetKit
  - ActivityKit
  - SwiftData (persistence)
  - UIKit (haptic feedback)
  - OSLog
- Optional later:
  - Speech framework / on-device transcription where appropriate
  - Cloud transcription service
  - HealthKit, only for optional sleep-context UX; never use health data as recording authorization.

Apple's current APIs provide WidgetKit Controls for Control Center, Lock Screen, and Action button, with actions implemented through App Intents. Apple also provides `AudioRecordingIntent` specifically for audio recording. `AudioRecordingIntent` requires a Live Activity to remain active while recording; otherwise recording stops.

---

## 2. Product invariants

### 2.1 Capture invariants

- Capture must be explicit.
- Wake Capture arming does NOT access the microphone.
- No continuous microphone monitoring.
- No wake-word detector implemented by the app.
- No automatic recording based solely on time, motion, sleep state, Focus state, screen state, or proximity.
- Audio capture must start only after an explicit user/system action.
- Recording must show the OS-provided recording indicator.
- The raw recording is the source of truth.
- Recording must be saved locally before being considered successful.
- Network availability must never be required to start/finish a recording.

### 2.2 Privacy invariants

- Request `NSMicrophoneUsageDescription`.
- Explain microphone use in plain language before/with the system permission request.
- Never attempt to hide microphone usage.
- Never attempt to circumvent lock-screen authentication.
- Never access microphone when not actively recording.
- Store recordings in the app's private container.
- Do not upload recordings automatically in MVP.
- Do not transmit recordings to an AI service unless the user explicitly enables cloud processing.

---

## 3. Primary UX

### 3.1 Before bed

The app UI provides:

Wake Capture:
- Armed / Disarmed
- Auto-disarm timer displayed when armed (shows remaining time or "Until I disarm")

Preferred capture:
- Audio

Optional:
- Auto-stop after silence: 30 seconds
- Maximum recording length: configurable, e.g. 5/10/30 minutes
- Auto-disarm after: 8 hours (default) / 12 hours / Until I disarm

Auto-disarm persistence:
- On arm, persist `armTimestamp` and `autoDisarmDuration` to UserDefaults.
- On disarm (manual or auto), clear both values.
- The source of truth for expiry is `armTimestamp + autoDisarmDuration > now`, not an in-memory timer. The in-memory timer is only a UI convenience for countdown display.
- On app launch or intent invocation, evaluate expiry first. If expired, transition to `DISARMED` before processing any other action.
- Arming must survive app termination, background kill, and device restart. iOS routinely kills background apps during sleep; tying arm state to process lifetime would break the core use case.

The user installs/configures a system Capture control.

Recommended system entry points:
1. Action button on supported iPhones.
2. Lock Screen control.
3. Control Center.
4. Home Screen widget/shortcut.
5. Siri/App Intents.

### 3.2 Night-time capture

Ideal path:

`locked phone -> Capture control -> recording starts immediately`

The user should not have to navigate through the application UI.

If the OS requires authentication or does not permit the requested operation from the current surface/state, fail safely and provide the minimum possible recovery path.

### 3.3 Recording UI

When the app process/recording surface is available:

- Large recording state.
- Elapsed time.
- Very large Stop action.
- No title/category/tag prompts.
- No confirmation dialog.
- Autosave.
- Optional haptic feedback for start/stop when the OS context permits it.

Example conceptual state:

RECORDING
00:17
[ STOP ]

### 3.4 Post-capture

Immediately persist:
- capture ID
- created timestamp
- duration
- local audio URL
- format/codec metadata
- completion status

Then return the user to the appropriate system/app state.

Do not force the user to name or organize the capture.

---

## 4. Wake Capture state machine

```
                  arm()                    startCapture()
 ┌──────────┐  ──────────>  ┌──────────┐  ──────────────>  ┌──────────┐
 │ DISARMED │               │  ARMED   │                   │ STARTING │
 └──────────┘  <──────────  └──────────┘                   └────┬─────┘
                 disarm()       ^  ^                            │
                                │  │            session ready   │
                                │  │                            v
                                │  │                       ┌──────────┐
                   stop ok ─────┘  │                       │RECORDING │
                   (persists as    │                       └──┬────┬──┘
                    SAVED)         │                          │    │
                                   │    user stop /           │    │  interruption /
                  ┌──────────┐     │    max duration          │    │  route loss /
                  │ STOPPING │ <───┼──────────────────────────┘    │  media reset
                  └──────────┘     │                               │
                                   │                               v
                                   │                      ┌─────────────┐
                                   └───── arm() ──────────│ INTERRUPTED │
                                                          └─────────────┘

                  ┌──────────┐
                  │  FAILED  │ <── any state, on unrecoverable error
                  └────┬─────┘
                       │
                       └───── arm() ────> ARMED
```

States:

- `DISARMED`
- `ARMED`
- `STARTING`
- `RECORDING`
- `STOPPING`
- `SAVED` (persistence state only — written to `CaptureRecord.state`)
- `INTERRUPTED` (persistence state — partial audio preserved after system interruption)
- `FAILED`

Transitions:

`DISARMED -> ARMED`
- user explicitly arms Wake Capture.
- also: `SAVED`, `FAILED`, `INTERRUPTED` -> `ARMED` (re-arm after terminal states).

`ARMED -> STARTING`
- explicit Capture system action.
- system entry points (WidgetKit control, Action button, Siri) require the user to be armed. If disarmed, the intent returns an error dialog instructing the user to arm first in the app.

`STARTING -> RECORDING`
- audio session configured and recorder successfully running.

`RECORDING -> STOPPING`
- user stop action, maximum-duration limit, or configured silence timeout.

`STOPPING -> ARMED`
- file closed, metadata committed, capture persisted with `saved` state.
- coordinator returns to `armed` so the user can immediately capture again without re-arming.
- the auto-disarm timer (if active) continues running; it is not reset by a capture cycle.

`RECORDING -> INTERRUPTED`
- system audio interruption, route loss, or media services reset.
- partial audio is finalized and persisted with `interrupted` state.

Any state -> `FAILED`
- unrecoverable permission/session/storage error.

Never transition:
- `ARMED -> RECORDING` without an explicit user action.

---

## 5. App Intents / system controls

Implement a dedicated App Intent for capture.

Implemented intents:

- `StartWakeCaptureIntent` — conforms to `AudioRecordingIntent`; requires armed state. If disarmed (or auto-disarm has expired), returns an error dialog instructing the user to arm first.
- `StopWakeCaptureIntent` — stops the current recording.
- `ArmWakeCaptureIntent` / `DisarmWakeCaptureIntent` — separate intents for arming and disarming.

The capture intent should be the canonical entry point used by:
- WidgetKit Control
- Action button configuration
- Control Center
- Lock Screen
- Siri/Shortcuts where supported

Do not duplicate recording logic inside each integration.

Apple's WidgetKit controls support buttons on the Lock Screen, Control Center and Action button, and the button action is implemented with an App Intent.

Important implementation detail:
- `perform()` must complete the required state persistence/action contract.
- Do not assume arbitrary long-running recording work can simply remain inside `perform()`.
- Use the recording architecture required by `AudioRecordingIntent` and ActivityKit.

All system entry points call a shared `CaptureCoordinator` singleton via `SharedCaptureCoordinator.shared`.

---

## 6. AudioRecordingIntent

Implement the audio capture action using Apple's `AudioRecordingIntent`.

Requirements:
- Conform the recording intent to `AudioRecordingIntent`.
- Use it to tell the OS the app performs audio recording.
- Start a Live Activity when recording starts.
- Keep the Live Activity active for the entire recording.
- Stop/update the Live Activity when recording ends.

Apple explicitly states that audio recording stops if the required Live Activity is not maintained.

The Live Activity should expose:
- recording state
- elapsed time
- stop action if supported by the chosen design
- minimal non-sensitive information

Do not put transcript/content into the Lock Screen Live Activity.

---

## 7. AVAudioSession

Create an `AudioSessionController`.

Responsibilities:
- configure AVAudioSession for recording.
- request microphone permission.
- activate/deactivate session.
- handle interruptions.
- handle route changes.
- handle media-services reset.
- handle phone/VoIP interruption.
- handle Bluetooth route changes.
- report errors to `CaptureCoordinator`.

Current configuration:
- category: `.record`
- mode: `.default`
- preferred sample rate: 44100 Hz
- preferred input channels: 1 (mono)
- no additional options (conservative — avoids unnecessary Bluetooth/output routing behavior)

Do not over-optimize audio quality for MVP. Favor reliable voice capture and low startup latency.

---

## 8. Recorder

Create an `AudioRecorder`.

Responsibilities:
- create unique recording file.
- start recording.
- expose elapsed time.
- stop/finalize file.
- verify file exists and has non-zero duration.
- return immutable recording metadata.

Use a format optimized for speech and reasonable storage size.

Current configuration:
- AAC in M4A container (`kAudioFormatMPEG4AAC`)
- 44.1 kHz
- mono
- `AVAudioQuality.high`

The recording API is isolated behind the `AudioRecording` protocol so the codec can be changed later.

---

## 9. Persistence

Use a small local persistence layer.

Implementation:
- SwiftData for metadata (`CaptureRecord` model, `CaptureRepository` actor).
- Files in Application Support for audio.
- Never store raw audio blobs inside the database.

Entity: `CaptureRecord`

- id: UUID (unique)
- createdAt: Date
- durationSeconds: Double
- relativePath: String (e.g. `Captures/<UUID>.m4a`)
- mimeType: String (default `audio/mp4`)
- codec: String (default `aac`)
- sampleRate: Double (default `44100`)
- channelCount: Int (default `1`)
- state: String (maps to `CaptureState` raw values)
- transcriptStatus: String (default `none`)
- uploadStatus: String (default `none`)
- title: String? (optional)
- tags: [String]

Recording files:
`Application Support/Captures/<UUID>.m4a`

File storage is managed by `RecordingFileStore` which handles directory creation, path resolution, existence checks, deletion, and available-storage queries (minimum 50 MB required to start).

A capture is successful only after:
1. recording is finalized;
2. file exists;
3. metadata is committed.

---

## 10. Interruption / failure handling

Must handle:
- incoming phone call
- another app taking audio focus
- microphone unavailable
- Bluetooth device disconnect
- app process interruption
- storage full
- permission revoked
- audio session failure
- device restart
- low-power conditions

Never silently claim success.

If recording is interrupted:
- finalize what was captured if possible.
- mark capture `INTERRUPTED`.
- preserve partial audio.
- do not discard user data.

**Open item: device power loss / sudden process kill.**

Not yet handled. The coordinator's state is in-memory only, so a kill mid-recording loses all awareness that a recording was in progress. Two problems compound here:

1. **Container format.** AAC in M4A requires a `moov` atom written at finalization (`AVAudioRecorder.stop()`). If stop never runs, the file on disk contains raw audio frames but the container is invalid and most readers won't open it. CAF (Core Audio Format) is append-friendly and recoverable without finalization, which would make crash recovery possible rather than theoretical.

2. **No recovery signal.** Nothing on disk tells the app that a recording was in progress when the process died. A lightweight breadcrumb file (capture ID, timestamp, file path) written at recording start and deleted on successful stop would let the app detect orphaned recordings on next launch and attempt recovery or cleanup.

---

## 11. Silence auto-stop

Not yet implemented. `CaptureCoordinator` declares `silenceTimeoutSeconds` (default 30) but no silence detection logic runs yet.

When implemented:
- user starts recording.
- detect sustained low input level.
- begin countdown after configured silence period.
- stop after countdown.
- reset countdown if speech resumes.

Never use silence detection to start recording.

Do not implement wake-word detection.

---

## 12. Permissions

Required:
- Microphone permission.

Permission UX:
1. Explain why microphone access is needed.
2. Request system permission.
3. If denied, show clear recovery instructions.
4. Never repeatedly prompt.
5. Never attempt to infer or bypass permission state.

If permission is revoked:
- capture action must fail safely.
- system control should reflect unavailable state if possible.

---

## 13. Lock Screen security

Treat the Lock Screen as an OS-controlled security boundary.

Do not:
- attempt to bypass authentication.
- expose sensitive transcript content.
- display private capture titles on the Lock Screen.
- use undocumented APIs.

Controls should use generic wording:
- "Capture"
- "Stop"

If a system surface requires authentication, accept that behavior.

Apple documents that controls can require device authentication and that locked-device interactions can be constrained by the system. Do not assume every WidgetKit interaction can perform arbitrary microphone work while locked.

---

## 14. Siri / Shortcuts

Expose:
- Start Capture
- Stop Capture
- Arm Wake Capture
- Disarm Wake Capture

Use App Intents metadata that makes the actions discoverable.

Natural language examples:
- "Start a capture."
- "Record this."
- "Arm Wake Capture."

Do not implement an always-on custom voice trigger.

---

## 15. Application architecture

Implemented modules:

`App`
- `WakeCaptureApp` — app lifecycle, SwiftData container setup

`CaptureCore`
- `CaptureCoordinator` — central state machine, orchestrates recording lifecycle
- `CaptureState` — state enum with transition guards
- `CaptureError` — error cases with user-facing messages
- `CaptureSession` — value type holding per-capture metadata
- `CaptureActivityAttributes` — Live Activity data model

`Audio`
- `AudioSessionController` — AVAudioSession management, permission handling, interruption/route/reset observation
- `AudioRecorder` — AVAudioRecorder wrapper behind `AudioRecording` protocol

`SystemIntegration`
- `SharedCaptureCoordinator` — singleton access to the coordinator
- `StartWakeCaptureIntent` — `AudioRecordingIntent` for starting capture
- `StopWakeCaptureIntent` — `AppIntent` for stopping capture
- `ArmWakeCaptureIntent` / `DisarmWakeCaptureIntent` — arm/disarm intents
- `WakeCaptureShortcuts` — Siri/Shortcuts phrase registration

`SystemIntegration` (extensions)
- `WakeCaptureWidgets` — WidgetKit control for Lock Screen / Control Center / Action button
- `WakeCaptureLiveActivity` — Live Activity UI (`CaptureActivityView`)

`Persistence`
- `CaptureRecord` — SwiftData model
- `CaptureRepository` — `@ModelActor` for thread-safe persistence behind `CaptureStoring` protocol
- `RecordingFileStore` — file path management and storage checks

`UI`
- `ContentView` — root navigation
- `OnboardingView`
- `SettingsView`
- `RecordingView`
- `CaptureHistoryView`
- `CaptureDetailView`

`Tests`
- `CaptureCoordinatorTests` — unit tests with protocol-based mocks
- `Mocks` — mock implementations of `AudioSessionProviding`, `AudioRecording`, `CaptureStoring`

`Processing` (not yet implemented)
- TranscriptionService protocol
- SummarizationService protocol

`CaptureCore` and `Audio` are independent of SwiftUI. `CaptureCoordinator` uses `@MainActor @Observable` for direct SwiftUI observation rather than the `actor` pattern, since UI binding requires main-thread access and the coordinator's state is inherently tied to the UI lifecycle.

---

## 16. Threading / concurrency

Uses Swift 6.0 strict concurrency.

Rules:
- recording lifecycle must be serialized.
- `CaptureCoordinator` is `@MainActor @Observable` — serialization is enforced by main-actor isolation. This was chosen over `actor` because the coordinator's state drives SwiftUI views directly.
- `CaptureRepository` is a `@ModelActor` for thread-safe SwiftData access.
- `AudioRecorder` uses `OSAllocatedUnfairLock` for its internal state to satisfy `Sendable`.
- UI observes state rather than mutating recording internals.
- file finalization must complete before persisting the capture record.

Avoid race:
`Start -> Stop -> Start` causing overlapping recorder instances.

---

## 17. MVP acceptance tests

### Permission
- Fresh install -> microphone permission requested.
- Denied -> clear failure.
- Granted -> capture works.

### Armed mode
- Arm -> microphone is NOT active.
- Disarm -> microphone is NOT active.

### Normal capture
- Capture -> audio begins.
- Stop -> file finalized.
- Relaunch app -> recording appears.

### Lock Screen/system entry
Test on real devices:
- locked screen
- unlocked screen
- Action button
- Lock Screen control
- Control Center
- Siri/Shortcuts

For every entry point record:
- whether it executes while locked;
- whether authentication is required;
- time from action to first audio sample;
- whether app process is launched;
- whether Live Activity appears;
- failure behavior.

### Interruptions
- phone call
- Bluetooth disconnect
- another recording app
- storage full
- permission revoked

---

## 18. Critical feasibility gate

Before building AI/cloud functionality, prove this exact flow on physical hardware:

`arm before sleep -> lock phone -> invoke system Capture -> microphone starts -> Live Activity remains active -> speak for 30 seconds -> stop -> audio file persists`

Do not declare the MVP platform-feasible based only on simulator behavior.

---

## 19. Non-goals

Do not implement:
- video capture
- continuous listening
- custom wake word
- automatic recording from motion/sleep detection
- cloud sync
- social sharing
- collaborative notes
- complex editing
- automatic recording without explicit user action

---

## 20. Current Apple API references

- WidgetKit Controls: https://developer.apple.com/documentation/widgetkit/controls-collection
- Controls from Lock Screen/Control Center/Action button: https://developer.apple.com/documentation/WidgetKit/Creating-controls-to-perform-actions-across-the-system
- AudioRecordingIntent: https://developer.apple.com/documentation/AppIntents/AudioRecordingIntent
- App Intents updates: https://developer.apple.com/documentation/updates/appintents
- Interactive widgets/Live Activities: https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities

These references should be rechecked against the SDK installed in Xcode before implementation because Apple can change API availability and behavior.
