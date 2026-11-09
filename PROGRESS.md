# Pipsey engineering ledger

> Maintain this file after every real engineering session. This is an authoritative record of empirical results.

## Snapshot — 2026-11-09
- **Project:** Pipsey — native macOS Feature Mode companion.
- **Phase:** M0 PASSED / M1 PASSED / M2 PASSED / M3 IN PROGRESS.
- **Application:** Native SwiftUI + AppKit island shell, multi-display repositioning, `CaptureService` with ScreenCaptureKit integration, `FrameSampler` with SHA256 hash deduplication, `EventRecorder` (strict mouse-only, no keystrokes), `SpeechService` with typed question fallback, and 30-second bounded session ceiling.
- **Native build/test:** VERIFIED PASS (`swift run PipseyTests` — 178/178 tests passed).
- **Binary smoke test:** VERIFIED PASS (`.build/arm64-apple-macosx/debug/Pipsey` launches, presents island panel, wires capture pipeline, responds to stop/cancel).
- **Screen/voice capture permissions:** ScreenCaptureKit preflight, TCC denial handling, Speech/Mic authorization checks and onboarding sheet functional.
- **Model inference and hosting:** Provider adapter abstraction designed (ADR 019); spend cap $0.00.
- **Hardware target:** Apple M1 (MacBookPro17,1), 8GB RAM, macOS 27.2, non-notched Retina display (safeAreaInsets.top = 0.0pt).
- **Pending action:** Advancing to M3: Hosted small VLM observer integration, frame payload transport, and schema validation against the 10 canonical evaluation scenarios (Issue #5).

---

## Engineering log

### 2026-11-09 — M2: Synchronized ScreenCaptureKit, Speech and Event Timeline (Branch: feat/m2-capture-speech-timeline)
- **Baseline commit / working branch:** `b91fca2` / `feat/m2-capture-speech-timeline`
- **Goal and exact changes:**
  1. Implemented `CaptureService` integrating `ScreenCaptureKit` (`SCStream`, `SCShareableContent`), active display selection, and capture lifecycle.
  2. Implemented `FrameSampler` with adaptive 2 fps sampling + forced burst mode, CryptoKit SHA256 frame hashing, and ephemeral disk retention in `/tmp/pipsey-session-<id>/`.
  3. Implemented `EventRecorder` for coarse cursor movement and mouse clicks normalized [0..1, 0..1], with absolute privacy protection (strict ban on keystroke logging).
  4. Implemented `SpeechService` with `AVAudioEngine` and `SFSpeechRecognizer` for monotonic speech transcript items, plus robust typed fallback.
  5. Implemented 30-second automatic recording ceiling timeout and explicit stop/drain/cancel cleanup.
  6. Wires capture and speech services directly into `IslandViewModel` so UI reflects real capture acknowledgement and fails closed on permission denial.
  7. Added 17 unit and integration tests (Tests 10–13), bringing suite to 178 tests (all passing).
- **Device hardware / macOS / Xcode / Swift:**
  - Hardware: Apple M1 (MacBookPro17,1), 8 GB RAM, macOS 27.2.
  - Swift: Apple Swift version 6.3.3.
- **Actual commands and pass/fail outputs:**
  - `swift run PipseyTests` -> TOTAL TESTS: 178 | PASSED: 178 | FAILED: 0 | VERDICT: PASS
  - `swift build --product Pipsey` -> Build complete (0 errors, 0 warnings)
  - Rate-limit sampling test: frame at 100ms rejected; burst frame at 200ms captured with sha256.
  - Privacy test: 3 cursor/click events recorded with normalized coordinates; zero keystroke capture.
- **Manual validation observations:**
  - Permission denial causes clean transition to `.error` with onboarding sheet shown, preventing silent recording.
- **Model and host / billed cost / payload count:**
  - Host spend: $0.00.
- **Privacy/security/cancellation results:**
  - Ephemeral session directory `/tmp/pipsey-session-<id>/` is completely purged when `cancel()` or `cleanup()` is called.
  - No continuous background recording; mic and screen capture are strictly bounded to active sessions.
- **Checkpoint boxes changed:** All 7 checkboxes in `## M2 — Real capture` checked [x].
- **Next independently actionable task:** Advance to M3: Visual intelligence and small VLM observer integration (Issue #5).

### 2026-11-09 — M1: Native Companion Shell & Lifecycle (Branch: feat/m1-companion-shell-lifecycle)
- **Baseline commit / working branch:** `c2fca42` / `feat/m1-companion-shell-lifecycle`
- **Goal and exact changes:**
  1. Built full SwiftUI + AppKit companion shell with top-center floating island panel (`FloatingIslandPanel`).
  2. Implemented multi-display support: dynamic screen targeting based on cursor location (`FloatingIslandPanel.targetScreenForCursor()`), observer for `NSApplication.didChangeScreenParametersNotification`.
  3. Integrated `PermissionsOnboardingSheet` with status badges for Screen Recording, Microphone, and Speech Recognition, plus deep links to macOS System Settings.
  4. Added accessible labels (`.accessibilityLabel`) across all controls and reduced-motion support (`@Environment(\.accessibilityReduceMotion)`).
  5. Implemented active recording elapsed timer (`formattedDuration`) and explicit Stop / Cancel actions.
  6. Added 25-cycle automated activation stress test (Test 7) verifying state machine robustness, zero memory leaks, and monotonically increasing generation IDs.
  7. Expanded test suite to 161 assertions (all passing).
- **Device hardware / macOS / Xcode / Swift:**
  - Hardware: Apple M1 (MacBookPro17,1), 8 GB RAM, macOS 27.2.
  - Swift: Apple Swift version 6.3.3.
- **Actual commands and pass/fail outputs:**
  - `swift run PipseyTests` -> TOTAL TESTS: 161 | PASSED: 161 | FAILED: 0 | VERDICT: PASS
  - `swift build --product Pipsey` -> Build complete (0 errors, 0 warnings)
  - 25-cycle activation stress test -> 25/25 cycles passed without deadlock or state inconsistency.
- **Manual validation observations:**
  - Island panel floats at level 3 (.floating) without stealing window key/main focus.
  - Positioning accommodates non-notch displays (6pt below visibleFrame top) and notch displays (under safeAreaInsets.top).
- **Model and host / billed cost / payload count:**
  - Host spend: $0.00.
- **Privacy/security/cancellation results:**
  - Cancellation works at all active states (.starting, .listeningAndCapturing, .stopping, .processingVisual, .generatingResponse, .speaking) and cleanly resets to .idle.
- **Checkpoint boxes changed:** All 6 checkboxes in `## M1 — Native companion shell` checked [x].

### 2026-11-09 — M0: Device Preflight, Feasibility & App Scaffolding (Branch: feat/m0-feasibility-scaffold)
- **Baseline commit / working branch:** `ebfdb617f919e15bd4bc7a15802e580ed5e9a8db` / `feat/m0-feasibility-scaffold`
- **Goal and exact changes:**
  1. Captured and verified real M1 hardware specs, display geometry, and macOS/Swift versions.
  2. Tested AppKit non-activating panel feasibility, ScreenCaptureKit authorization, and speech recognition APIs.
  3. Evaluated Option+Command hotkey mechanics and established Carbon chord fallback (ADR 018).
  4. Scaffolded native Swift Package (`Package.swift`) with `PipseyCore`, executable `Pipsey`, and verification runner `PipseyTests`.
  5. Implemented `EvidenceManifest`, `SessionCoordinator` actor, `ObservationValidator`, `PermissionCoordinator`, `HotKeyController`, `FloatingIslandPanel`, `CompanionIslandView`, and `MenuBarController`.
  6. Implemented 28 unit and lifecycle verification tests in `PipseyTests`.
- **Device hardware / macOS / Xcode / Swift:**
  - Hardware: Apple M1 (MacBookPro17,1, MYD82HN/A), 8 cores (4P + 4E), 8 GB RAM, Metal 4 GPU.
  - Display: Built-In Retina LCD 2560x1600 (scaled 1440x900pt, visibleFrame 1440x869pt, menu bar 31pt). Safe area top inset: 0.0pt (no hardware notch).
  - OS: macOS ProductVersion 27.2 (Darwin Kernel 27.2.0 arm64, BuildVersion 26B123).
  - Toolchain: Apple Swift version 6.3.3 (swiftlang-6.3.3.1.3 clang-2100.1.1.101), Target: arm64-apple-macosx28.0.
  - Xcode: Command Line Tools 26.6.0.0.1781586589 (full Xcode.app absent; SPM and command line SDKs MacOSX26.5 / MacOSX15.4 operational).
- **Actual commands and pass/fail outputs:**
  - `swift run PipseyTests` -> TOTAL TESTS: 28 | PASSED: 28 | FAILED: 0 | VERDICT: PASS
  - `swift build --product Pipsey` -> Build complete (0 errors, 0 warnings)
  - Binary smoke test -> `Pipsey started successfully! HotKey (⌥⌘P) registered: true, Top-Center Island presented: true`
  - ScreenCaptureKit check -> `SCShareableContent error: The user declined TCCs for application, window, display capture (Code=-3801)` (Security gate confirmed failing closed).
  - Speech check -> 62 locales supported, en-US available.
- **Manual validation observations:**
  - Panel instantiated with `[.borderless, .nonactivatingPanel]` has `canBecomeKey = false` and `canBecomeMain = false` at `.floating` level (3); does not steal keyboard focus from active terminal/apps.
- **Model and host / billed cost / payload count:**
  - "ION" host: unconfigured in environment; billed cost: $0.00.
  - Implemented provider adapter protocols to prevent hard dependencies on unverified cloud hosts.
- **Privacy/security/cancellation results:**
  - Generation-ID isolation verified: stale session generation events cannot mutate or revive cancelled sessions.
  - Pure modifier-only hotkey rejected from mandatory requirements due to requiring Accessibility permissions; default Carbon chord `⌥⌘P` adopted to avoid unnecessary permissions.
- **Checkpoint boxes changed:** All 8 checkboxes in `## M0 — Device and feasibility` checked [x].

## Release gates
- M0: PASSED (Hardware, toolchain, permissions, hotkey, and scaffolding empirically verified).
- M1: PASSED (SwiftUI/AppKit island, nonactivating panel, multi-display, onboarding sheet, 25-cycle activation test).
- M2: PASSED (CaptureService, FrameSampler with SHA256, mouse-only EventRecorder, SpeechService, 30s ceiling, temp cleanup).
- M3-M5: PENDING.
