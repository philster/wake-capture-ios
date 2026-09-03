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

- Language: Swift
- UI: SwiftUI
- Minimum deployment target: choose the lowest iOS version that supports the required WidgetKit/App Intents control stack; prefer the current major iOS SDK during implementation.
- Xcode: current stable Xcode compatible with the deployment target.
- Architecture: native iOS application; do not use React Native for the system integration layer.
- Frameworks:
  - SwiftUI
  - AVFoundation
  - AppIntents
  - WidgetKit
  - ActivityKit
  - UserNotifications only if needed
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

Preferred capture:
- Audio

Optional:
- Auto-stop after silence: 30 seconds
- Maximum recording length: configurable, e.g. 5/10/30 minutes

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

States:

- `DISARMED`
- `ARMED`
- `STARTING`
- `RECORDING`
- `STOPPING`
- `SAVED`
- `FAILED`

Transitions:

`DISARMED -> ARMED`
- user explicitly arms Wake Capture.

`ARMED -> STARTING`
- explicit Capture system action.

`STARTING -> RECORDING`
- audio session configured and recorder successfully running.

`RECORDING -> STOPPING`
- user stop action, maximum-duration limit, or configured silence timeout.

`STOPPING -> SAVED`
- file closed and metadata committed.

Any state -> `FAILED`
- unrecoverable permission/session/storage error.

Never transition:
- `ARMED -> RECORDING` without an explicit user action.

---

## 5. App Intents / system controls

Implement a dedicated App Intent for capture.

Recommended conceptual intents:

- `StartWakeCaptureIntent`
- `StopWakeCaptureIntent`
- optionally `ToggleWakeCaptureIntent` for an in-app/widget state control.

The capture intent should be the canonical entry point used by:
- WidgetKit Control
- Action button configuration
- Control Center
- Lock Screen
- Siri/Shortcuts where supported

Do not duplicate recording logic inside each integration.

All system entry points call a shared `CaptureCoordinator`.

Apple's WidgetKit controls support buttons on the Lock Screen, Control Center and Action button, and the button action is implemented with an App Intent.

Important implementation detail:
- `perform()` must complete the required state persistence/action contract.
- Do not assume arbitrary long-running recording work can simply remain inside `perform()`.
- Use the recording architecture required by `AudioRecordingIntent` and ActivityKit.

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

Recommended initial configuration:
- category appropriate for recording/voice capture.
- mode optimized for spoken voice where supported.
- options chosen conservatively; avoid unnecessary Bluetooth/output routing behavior.

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

Suggested MVP:
- AAC in M4A container unless testing demonstrates a better requirement.
- 44.1 kHz or 48 kHz.
- mono where appropriate for voice capture.

Keep the recording API isolated so the codec can be changed later.

---

## 9. Persistence

Use a small local persistence layer.

Recommended MVP:
- SQLite/Core Data/SwiftData for metadata.
- Files in Application Support for audio.
- Never store raw audio blobs inside the database.

Entity:

`Capture`
- id: UUID
- createdAt: Date
- durationSeconds: Double
- fileURL: relative/path-safe identifier
- mimeType
- codec
- sampleRate
- channelCount
- state
- transcriptStatus
- uploadStatus
- title: optional
- tags: optional

Recording files:
`Application Support/Captures/<UUID>.m4a`

Use atomic writes where possible.

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

---

## 11. Silence auto-stop

MVP optional.

Implement a configurable silence detector only after reliable basic recording exists.

Suggested behavior:
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

Recommended modules:

`App`
- app lifecycle
- dependency injection

`CaptureCore`
- CaptureCoordinator
- CaptureState
- CaptureError
- CaptureSession

`Audio`
- AudioSessionController
- AudioRecorder
- AudioRouteMonitor
- AudioInterruptionHandler

`SystemIntegration`
- App Intents
- WidgetKit Controls
- Siri/Shortcuts
- Live Activity

`Persistence`
- CaptureRepository
- RecordingFileStore

`UI`
- Onboarding
- WakeModeSettings
- RecordingView
- CaptureHistory
- CaptureDetail

`Processing`
- TranscriptionService protocol
- SummarizationService protocol

Keep `CaptureCore` independent of SwiftUI.

---

## 16. Threading / concurrency

Use Swift Concurrency.

Rules:
- recording lifecycle must be serialized.
- `CaptureCoordinator` should be an `actor` or otherwise enforce serialized state transitions.
- UI observes state rather than mutating recording internals.
- file finalization must complete before publishing `SAVED`.

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
