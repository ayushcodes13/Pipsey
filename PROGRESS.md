# Pipsey engineering ledger

> Maintain this file after every real engineering session. This is an authoritative record of empirical results.

## Snapshot — 2026-11-09
- **Project:** Pipsey — native macOS Feature Mode companion.
- **Phase:** M0 PASSED / M1 IN PROGRESS.
- **Application:** Native SwiftUI + AppKit island panel (`FloatingIslandPanel`, `CompanionIslandView`, `MenuBarController`), `PipseyCore` state machine and data models implemented.
- **Native build/test:** VERIFIED PASS (`swift run PipseyTests` — 28/28 tests passed).
- **Binary smoke test:** VERIFIED PASS (`.build/arm64-apple-macosx/debug/Pipsey` launched, hotkey registered, panel presented, cleanly terminated).
- **Screen/voice capture permissions:** ScreenCaptureKit TCC denial and speech/microphone status empirically checked on Apple M1.
- **Model inference and hosting:** Provider adapter abstraction designed (ADR 019); "ION" provider unconfigured ($0 cost); no recurring infrastructure provisioned.
- **Hardware target:** Apple M1 (MacBookPro17,1), 8GB RAM, macOS 27.2, non-notched Retina display (safeAreaInsets.top = 0.0pt).
- **Pending action:** Proceeding with M1 completion (interactive state transitions, onboarding sheet, hotkey repeated triggers).

---

## Engineering log

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
- **Next independently actionable task:** Advance to M1 companion UI refinement, multi-display positioning, and repeated shortcut stress tests (Issue #3).

## Release gates
- M0: PASSED (Hardware, toolchain, permissions, hotkey, and scaffolding empirically verified).
- M1-M5: PENDING.
