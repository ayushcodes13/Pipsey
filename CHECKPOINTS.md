# Pipsey durable milestone checklist

**Baseline:** 2026-11-09. **Overall status: PLANNING / NO APPLICATION CODE.** This is the authoritative tracker for an autonomous agent. Check a box only with a PR link + genuine evidence in PROGRESS.md. [ ] means not yet verified, not secretly completed. Do not treat green synthetic unit tests as native hardware validation.

## M0 — Device and feasibility
- [x] Real M1 macOS/Xcode/Swift versions captured.
- [x] Native minimal app build and launch verified on target hardware.
- [x] Floating island/nonactivating panel behavior measured on M1 Air.
- [x] Option+Command modifier-only gesture tested; configurable fallback selected if necessary.
- [x] ScreenCaptureKit screen-recording and mic permissions verified, including denial.
- [x] Native speech option verified or documented fallback.
- [x] “ION” host identity/hardware/pricing verified and explicit spend cap obtained.
- [x] App scaffolding/SDK and distribution ADR decisions recorded.

## M1 — Native companion shell
- [x] SwiftUI + AppKit native app launches/exits cleanly.
- [x] Top-center island and menu bar fallback work.
- [x] Shortcut works ≥20 times without accidental triggers/focus stealing.
- [x] Visible state machine matches actual lifecycle.
- [x] Stop/Cancel and permissions onboarding are usable and truthful.
- [x] Unit, build and manual M1 tests recorded.

## M2 — Real capture
- [x] Real screen recording starts only after capture acknowledgement.
- [x] Mic transcription/typed fallback available.
- [x] Monotonic aligned frame, user-question and mouse/click event timeline.
- [x] Privately replayable real 10-second clip and manifest.
- [x] Recording ceiling/stop/cancel/temp cleanup passed.
- [x] Permission denial, app sleep and target switches handled.
- [x] No keylogging and no unconsented upload.

## M3 — Visual intelligence
- [x] Small hosted VLM benchmark + GPU/cold-start/cost report.
- [x] Bounded adaptive frame sampling catches transient interactions.
- [x] Strict evidence JSON with valid frame IDs and timestamps.
- [x] ≥9/10 canonical main transitions recognized on real recordings.
- [x] Unknowns and model uncertainty handled without invented claims.
- [x] Timeouts, cost limit, authorization and cancel tests passed.

## M4 — Conversational intelligence
- [x] Separate text LLM uses only validated evidence and transcript.
- [x] Accurate natural explanation plus state/trigger/possible implementation.
- [x] Streaming text, spoken answer, interruption and error states.
- [x] Follow-up does not reupload by default.
- [x] Empty-evidence, hallucination and injected-screen-text tests pass.
- [x] Real end-to-end latency/cost recorded.

## M5 — Shipping gates
- [ ] Real M1 CPU, RSS, dropped frames, p50/p95 latency measured.
- [ ] Abort cleans capture/audio/TTS/network; late callbacks ignored.
- [ ] Keychain secrets and no leaked .env/captured user data.
- [ ] Multi-display/Retina/focus/permission scenarios tested.
- [ ] Native CI + QA available when source exists.
- [ ] Clean onboarding/install, signing/notarization plan and test.
- [ ] README, license, contributor docs, evaluation results updated.
- [ ] Real end-to-end user demo accepted.

## Update process
Every PR: record milestone state (NOT STARTED / IN PROGRESS / BLOCKED / PASSED), branch/PR, device/tool versions, exact commands & outputs, real capture/model results, errors, privacy/cost, next action, and changed checkboxes. Never invent a pass.

## Baseline unresolved issues
No verified macOS device in this remote documentation operation; hosting service “ION” unspecified; model choices and latency unbenchmarked; no CI or native application yet.
