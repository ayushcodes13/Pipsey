# Pipsey — Canonical Agent Instructions

**These are binding repository instructions for coding agents.** The CLAUDE.md file must be a Git symlink to this file (never duplicate or drift). Read README.md, PRODUCT.md, ARCHITECTURE.md, API_CONTRACTS.md, IMPLEMENTATION_PLAN.md, CHECKPOINTS.md, EVALUATION.md, SECURITY.md, DEVELOPMENT.md, DECISIONS.md and PROGRESS.md before editing.

## Mission and current state

Build a **real, working, native macOS companion called Pipsey**. Its first and only MVP workflow is Feature Mode: activate, ask verbally, demonstrate a UI interaction, end capture, receive an evidence-grounded explanation, then ask follow-ups. Never imply that a planned feature is already shipped. The current repository initially contains **planning only**; don't mistake documents for a functioning product.

## Unalterable intent
- User-invoked, bounded screen-and-voice recording. Clearly visible capture state; stop and cancel both work.
- Top-center/notch-inspired, friendly companion that doesn't steal app focus; adapt on non-notched M1 Air displays.
- **Two independent AI roles:** small, remotely hosted VLM for observations; separate text LLM for natural explanation. STT/TTS aren't additional general LLM roles.
- A typed, timestamped, evidence-linked observation timeline. Distinguish observed from inferred; avoid confident guesses.
- Full macOS permissions, revocation handling, privacy controls, Keychain secrets, cleanup and explicit upload consent.
- No Debug Mode, autonomous actions, continuous capture, code generation, Windows, payments or multi-user cloud platform in MVP.
- Respect original art and brand: the selected Pipsey peeking robot asset is the brand reference; don't reuse HeyClicky proprietary branding or claim affiliation.

## Execution protocol
1. Inspect git status, branch, current implementation, platform/tool availability and docs. Preserve user changes.
2. Read CHECKPOINTS.md and PROGRESS.md. Work the **earliest incomplete checkpoint** with dependency prerequisites satisfied.
3. Design the smallest vertical slice, record assumptions and test plan, implement it, run actual checks.
4. Use feature branches and reviewable PRs; don't force push, rewrite history, or merge unchecked work. Avoid destructive commands. Commit coherent units. Never put credentials, recordings or private screenshots into Git.
5. Update CHECKPOINTS.md and PROGRESS.md in the *same PR* with factual evidence: commands, pass/fail counts, hardware/OS, manual observations, costs, blockers and next task. No fabricated green checks.
6. Continue through milestones autonomously when tests pass; stop only on a real external dependency, unsafe permission, cost approval, or irreducible blocker. Paid API runs within explicitly approved budget are allowed; never silently provision recurring paid infrastructure.
7. If test infrastructure doesn't exist, create it in the milestone that requires it. A green mocked test is not proof of native capture or model accuracy.
8. If an architecture choice fails, document findings in DECISIONS.md and select a safe alternative; preserve product intent.
9. If running in Linux/cloud CI without macOS or a real display, do what can be validated there, mark macOS-specific gates BLOCKED, and provide concrete commands for real-device checks. Never call those gates passed.
10. Keep the user-facing README truthful: badge/status must reflect observed implementation, never future plans.

## Build constraints
- Prefer SwiftUI + AppKit for the shell, ScreenCaptureKit for capture, supported Apple speech APIs with fallback, and narrowly scoped service protocols.
- Avoid Electron, unnecessary backend frameworks, databases, agents, and needless dependencies.
- App's main responsibilities: shell, session state machine, capture/timestamps, speech, sampling, VLM transport, evidence validation, conversation/TTS, storage and permissions.
- Server responsibilities only if needed: authenticated VLM inference, request limits, schema/version enforcement, cost/timeouts. Model backend could be an existing hosted endpoint. **Hosting platform ION is unspecified and must be confirmed via an actual deployment probe.**
- Real model and provider selection follow benchmarks, not popularity claims. Qwen3-VL 2B is a *candidate*, not a validated commitment.
- Shortcut **Option+Command** is desired UX, not a guaranteed OS hotkey; validate conflict/accidental activation and offer a configurable fallback if necessary.
- Treat OS accessibility/window metadata as optional enhancement; **Feature Mode must not depend on perfect accessibility grounding**.
- Fail closed: no background capture in idle, no silent upload, no model statement unsupported by evidence, no secret logging.
- Cancel must propagate to screen/audio capture, frame sampler, VLM jobs, text streaming and TTS; cleanup temporary files and prevent stale async callbacks from reviving a session.

## Interface and evidence contract
Use API_CONTRACTS.md as the protocol baseline. Every observation contains session ID, time span, evidence frame IDs and explicit observation/inference/unknown markers. The text model sees a bounded validated timeline and transcript, not untrusted arbitrary model instructions. Preserve source provenance.

## Quality gates
Follow EVALUATION.md. For the 10 reference behaviors, target at least 9/10 main visible transition detections under explicitly documented test conditions; measure timing and false explanations. All acceptance gates must have direct proof (capture playback, logs without secrets, test outputs, manual M1 sign-off). No placeholder output or hard-coded demo disguised as inference.

## Symlink check
The only authoritative policy is AGENTS.md. CLAUDE.md is a symlink to AGENTS.md with Git mode 120000; verify using git ls-files -s and test -L CLAUDE.md on a supported checkout. If symlink support is absent, ensure agent loads AGENTS.md as the fallback.

## Done means
A feature is done when its use case is executed on the target platform, its errors/cancellation work, tests pass, relevant documentation updates are committed and PROGRESS.md includes evidence. If anything is untested, mark it NOT VERIFIED.
