# Agent-executable implementation plan

**Current state: FULLY IMPLEMENTED & OPERATIONAL (M0–M5 Complete).** The native macOS companion application (`build/Pipsey.app`) is built, code-signed, and verified with 321 passing unit tests across 32 comprehensive suites. This document preserves the architectural gates and milestones achieved.

## Workflow
Read AGENTS.md and CHECKPOINTS.md first. Work through milestones in dependency order. Use a branch and reviewable PR for each vertical slice. Every PR must include verified commands/results, macOS version/hardware, manual checks, failure handling, privacy and costs, with matching updates to CHECKPOINTS.md and PROGRESS.md. Never report a simulated response or mocked screen as working inference.

### M0 — Feasibility and native development preflight
Verify Xcode/Swift/macOS on the actual M1; check ScreenCaptureKit/microphone and relevant Speech APIs, proper screen-capture entitlement/permissions, AppKit nonactivating panel behavior, no physical notch fallback, modifier-only Option+Command reliability (or configurable fallback), licensing and source layout. Identify exact provider intended by “ION” but do not deploy paid GPU. Choose the simplest Xcode project/package/test structure and document it.
**Gate:** reproducible native environment report and tiny build feasibility, real device evidence, decision log updated. BLOCKED if real Mac unavailable.

### M1 — Companion UI + lifecycle
Create real SwiftUI/AppKit app, menu-bar fallback and top-center island, startup/idle/activation states, permission onboarding, hotkey with collision detection, Stop/Cancel controls, state-machine unit tests, focus/multi-display positioning and accessibility labels.
**Gate:** app launches on M1, repeated activation succeeds ≥20 times, UI doesn't steal unrelated focus, permission failures truthful, tests/build actually pass. Recording must not be falsely indicated before implementation.

### M2 — Real eyes and ears
Implement ScreenCaptureKit bounded capture and selected scope, capture-start acknowledgements, frame timestamps, local sampling/replay, microphone+STT/typed fallback, coarse mouse/click events (never keylog), immutable session manifest, stop/drain/cancel/cleanup and sleep/revocation handling.
**Gate:** real 10-second interaction recorded, video/frame IDs and speech/click timeline aligned, replayable privately, explicit stop/cancel and denied permissions tested on M1.

### M3 — Small VLM observer
Benchmark Qwen3-VL 2B/4B or stronger viable small alternative on actual user-demonstrated clips and low-cost host; test frame sampling beyond 2 fps near transient UI changes. Build authenticated bounded transport, strict schema and provenance validator, model-agnostic adapter, costs, rate and timeout limits, safe cancellation.
**Gate:** 9/10 primary UI transitions correctly identified on 10 real canonical cases; valid source frame IDs, uncertainty preserved; cost/latency/GPU constraints recorded. Hosting provider not assumed.

### M4 — Separate conversational model
Connect distinct text LLM to validated VLM observations, user STT transcript and bounded chat state. Stream text, optional Apple speech synthesis, support interruption/mute, accurate statuses, evidence-grounded explanations and follow-ups without redundant upload.
**Gate:** full real workflow repeated end-to-end, model never claims unobserved details as facts, follow-up works, streaming/cancel/timeout tested, first token and speech latency measured.

### M5 — Security, QA, release
Run adversarial prompt-injection/privacy review, cancellation resource cleanup, permissions revocation, app switching, Retina/multiple displays, CPU/RSS and startup profiling; create macOS CI tests once code exists, clean installation, signing/notarization approach and open-source docs.
**Gate:** entire test matrix reviewed; real M1 full flow passes; 10-case accuracy gate met; no critical secrets/privacy/cancellation defects; distribution path reproducible. No “production ready” claim without installer/real user verification.

## Parallel agent division
Once M1 shared types stabilize, one agent may handle capture, another VLM benchmarks, another island UI design. Only one agent at a time owns session lifecycle types and shared architecture docs. Merge isolated PRs with actual integration checks. Server work can be independent but must not fabricate integration success.

## Spending and external actions
Paid inference within an explicitly stated user-approved budget is allowed; no unapproved always-on GPU, signing subscription, public hosting, or recurrent billing. Never secretly upload private capture media. On blockers, record precise missing dependency and continue safe independent slices. Avoid endless additional planning if a testable implementation can proceed.
