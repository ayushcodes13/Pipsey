# Autonomous goal-mode implementation handoff

## Bootstrap
Read **AGENTS.md** first (CLAUDE.md symlinks to it), then README.md, PRODUCT.md, ARCHITECTURE.md, API_CONTRACTS.md, IMPLEMENTATION_PLAN.md, CHECKPOINTS.md, EVALUATION.md, SECURITY.md, DEVELOPMENT.md, DECISIONS.md and PROGRESS.md.

## Current State & Goal
The native macOS **Pipsey** application is fully implemented, verified, and operational (M0–M5 complete, 321 passing unit tests). It provides complete Feature Mode workflow: global hotkey (`⌥⌘P` or `⌥⌘` chord) → top-center Notch Island or Liquid Glass Floating Pod → verbal inquiry → bounded ScreenCaptureKit recording with 5-bar reactive audio waveform → hosted VLM visual observation timeline → independent conversational LLM grounded explanation → spoken voice & follow-up chat. Supports optical Telescope mode (`⌃⌥⌘`), 30-second curiosity peeking, and BYOK Keychain credentials.

## Work sequence
1. Check git status/current HEAD and preserve existing work; M0 machine/SDK/API feasibility. Record actual environment.
2. Start M1 app scaffold, shell, hotkey and session state machine. Execute build/tests and real Mac smoke test.
3. Implement M2 real ScreenCaptureKit, speech, synchronized samples and cancellation. Validate with actual 10-second clip.
4. Implement M3 model endpoint/benchmarks after verifying exact “ION” hosting and explicit budget; use validated structured evidence.
5. Implement M4 conversation/voice/follow-ups only on real observer outputs. Don't fake a responsive assistant.
6. Harden M5: privacy, multi-display, performance, installation, CI/release; document real evidence.

## Operating rules
Work proactively in PR-sized coherent increments and continue to next milestone when dependencies/tests permit. Use separate parallel agents only for isolated work; serialize changes to shared state/architecture. Update CHECKPOINTS.md + PROGRESS.md with commands, results, device, costs and blockers. Avoid unnecessary clarifying questions; make reversible choices and document them. Pause for genuinely missing access, paid recurring infrastructure approval, device-only permissions or dangerous actions. Don't claim a test passed if it wasn't run.

## Key non-goals
No complete HeyClicky clone, autonomous clicks, Debug Mode, full codebase indexing, automatic code generation, 24/7 recording, Windows app, unnecessary database or paid SaaS stack.

## Final end-to-end proof
On actual M1: launch → activate reliably → ask → demonstrate a hover interaction → stop → inspect validated frame-linked evidence → listen/read explanation → ask follow-up → cancel/clear safely. Match EVALUATION.md and release gates before “ready”.
