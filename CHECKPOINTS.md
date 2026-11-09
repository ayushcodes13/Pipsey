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
- [ ] Real screen recording starts only after capture acknowledgement.
- [ ] Mic transcription/typed fallback available.
- [ ] Monotonic aligned frame, user-question and mouse/click event timeline.
- [ ] Privately replayable real 10-second clip and manifest.
- [ ] Recording ceiling/stop/cancel/temp cleanup passed.
- [ ] Permission denial, app sleep and target switches handled.
- [ ] No keylogging and no unconsented upload.

## M3 — Visual intelligence
- [ ] Small hosted VLM benchmark + GPU/cold-start/cost report.
- [ ] Bounded adaptive frame sampling catches transient interactions.
- [ ] Strict evidence JSON with valid frame IDs and timestamps.
- [ ] ≥9/10 canonical main transitions recognized on real recordings.
- [ ] Unknowns and model uncertainty handled without invented claims.
- [ ] Timeouts, cost limit, authorization and cancel tests passed.

## M4 — Conversational intelligence
- [ ] Separate text LLM uses only validated evidence and transcript.
- [ ] Accurate natural explanation plus state/trigger/possible implementation.
- [ ] Streaming text, spoken answer, interruption and error states.
- [ ] Follow-up does not reupload by default.
- [ ] Empty-evidence, hallucination and injected-screen-text tests pass.
- [ ] Real end-to-end latency/cost recorded.

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
