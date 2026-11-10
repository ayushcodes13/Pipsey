# Product specification — Pipsey Feature Mode

**Version:** 1.0 Feature Mode MVP Verified | **Owner intent:** original open-source desktop companion | **Target:** Apple Silicon macOS.

## Problem and promise
You see an interaction in an app and wonder “What just happened, and how could I build it?” Screenshots don't capture hover timing, animations and state changes. Pipsey observes a *short user-demonstrated interaction*, then explains observed UI behavior and suggests plausible engineering patterns. It cannot inspect another app's source code from pixels; it must not pretend otherwise.

## Primary persona and core story
Builder, software engineer, designer or student. While using any app, the user presses the selected shortcut, asks “Pipsey, how does this work?”, manually triggers a hover/click/drag transition, and stops recording. Pipsey responds with (a) concise plain-language observation, (b) trigger and before/after states, (c) implementation hypothesis explicitly qualified, (d) optional follow-up conversation. No code writing is required for v1.

## Main journey
1. Idle: silent, tiny companion orb or menu-bar utility; microphone and screen access are OFF. Features an ambient 3.2-second cyan breathing pulse and a 30-second curiosity peeking cadence (8s motion / 30s rest).
2. Activation: global hotkey (default `⌥⌘P` or `⌥⌘` chord); activates bounded recording status with pulsing recording jewel and live audio waveform visualizer.
3. Telescope Mode: pressing `⌃⌥⌘` (Control+Option+Command) activates optical inspection HUD with rotating aperture radar sweep and live crosshair screen scanning.
4. Question: STT receives speech; partial text shows in UI. If speech fails, typed question fallback is available.
5. Demonstration: capture intended display/window and synchronized mouse location/click timestamps. Never log typed keystroke content or background audio other than explicitly activated mic input.
6. Stop: halt sources and finalize local frame/event timeline. Show actual processing state.
7. Observe: sample frames and VLM returns timestamped visual observations linked to frame IDs.
8. Explain: a text LLM produces a concise, natural, streaming explanation; optional speech output. Model cannot claim it saw events not supported by evidence.
9. Follow-up: queries reuse transcript, observations, and answer history with code-level insights.
10. Dismiss/delete: user can clear session, end all work, and purge temporary capture artifacts.

## Companion UI Form Factors
- **Liquid Glass Floating Pod:** Translucent obsidian glass pebble ($46\times46\text{pt}$) with specular top rim highlight, ambient cyan breathing pulse, and magnetic corner snapping. Draggable anywhere across displays with "Snap to Anchor Corner" reset. Fluidly expands into a $196\times46\text{pt}$ pill on hover.
- **Screen Notch Island:** Flush top-center overlay (`Y = 0`) with concave Bezier ear curves matching MacBook notch geometry and non-notched M1 displays. Reduces motion gracefully.

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
