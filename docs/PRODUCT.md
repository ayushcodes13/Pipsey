# Product specification — Pipsey Feature Mode

**Version:** planning baseline 0.1 | **Owner intent:** original open-source desktop companion | **Target:** Apple Silicon macOS.

## Problem and promise
You see an interaction in an app and wonder “What just happened, and how could I build it?” Screenshots don't capture hover timing, animations and state changes. Pipsey observes a *short user-demonstrated interaction*, then explains observed UI behavior and suggests plausible engineering patterns. It cannot inspect another app's source code from pixels; it must not pretend otherwise.

## Primary persona and core story
Builder, software engineer, designer or student. While using any app, the user presses the selected shortcut, asks “Pipsey, how does this work?”, manually triggers a hover/click/drag transition, and stops recording. Pipsey responds with (a) concise plain-language observation, (b) trigger and before/after states, (c) implementation hypothesis explicitly qualified, (d) optional follow-up conversation. No code writing is required for v1.

## Main journey
1. Idle: silent, tiny island or menu-bar utility; microphone and screen access are OFF.
2. Activation: intended Option+Command gesture; on genuine activation request OS permissions if needed, show scope, start time and recording status. Support a fallback configurable shortcut.
3. Question: STT receives speech; partial text shows in UI. If speech fails, a typed question remains possible.
4. Demonstration: capture intended display/window and synchronized mouse location/click timestamps. Never log typed keystroke content or background audio other than the explicitly activated mic input. User controls everything.
5. Stop: halt sources and finalize local frame/event timeline. Show actual processing state.
6. Observe: sample frames and VLM returns timestamped visual observations linked to frame IDs. Catch missing/ambiguous evidence.
7. Explain: a text LLM produces a concise, natural, streaming explanation; optional speech output. Model cannot claim it saw events not supported by evidence.
8. Follow-up: queries reuse transcript, observations and answer history. Revisit video only on explicit request; follow-ups may stay available until session ends.
9. Dismiss/delete: allow user to clear session, end all work and remove temporary capture artifacts.

## Companion UI
Compact dark top-center pill while idle. Expands minimally when listening/capturing/answering. Designed for an M1 MacBook Air with **no physical notch** as well as notch Macs. Must not obstruct interaction, steal focus or capture itself. Subtle eye/peeking mascot animation can be aesthetic but status text/icons must be accessible. Reduce motion support; proper contrast and VoiceOver descriptions.

## State machine (source of truth)
IDLE → STARTING → LISTENING_AND_CAPTURING → STOPPING → PROCESSING_VISUAL → GENERATING_RESPONSE → SPEAKING / READY_FOR_FOLLOWUP → IDLE.
Any non-idle state can enter CANCELLING → IDLE; recoverable failures enter ERROR with an actionable, accurately reported reason. Use separate independent recording, STT, inference and playback substates where concurrent. Never set “observing complete” before receiving verified result. Strict session-id checks prevent stale callbacks.

## Limits and defaults (change after device benchmarks)
- Default manual capture ceiling: 30 seconds; clear timer and warning before limit, auto-stop safely at limit.
- Explicit scope selection: active window when supported, otherwise selected display with an honest scope indicator.
- Frame sampling: start with 2 fps + local event/change-triggered burst frames, tune after evaluation. Keep the full local recording only for explicitly opted-in debug/replay; minimize retention.
- One active capture session per app instance; reject or focus existing session if activation repeats.
- No background continuous recognition or capture. Microphone off in IDLE.
- User-visible Cancel, Stop, retry and Clear controls. Transcripts are private unless user explicitly exports.

## Output shape and examples
The response should say: “When you moved over the menu, a panel appeared. When you moved away, it disappeared. A likely implementation is a hover state with conditional rendering and a transition; I can't see its underlying source.” Never say “they used React” based only on a recording.

## Acceptance outcomes
An M1 user can reliably initiate and stop a real capture; captures and transcript align; the observer spots a meaningful change; the conversational model remains evidence-grounded; follow-ups work; cancel and permission denial fail safely. See EVALUATION.md.

## Non-goals
Screen surveillance, autonomous macOS control, reading secrets, scraping private app source, code generation, debugging repositories, browser extensions, Windows support, teams, accounts or billing.

## Research and provenance
Original inspiration: https://www.heyclicky.com/ and https://github.com/farzaa/clicky . This product spec describes **Pipsey**, not confirmed internals of proprietary HeyClicky.
