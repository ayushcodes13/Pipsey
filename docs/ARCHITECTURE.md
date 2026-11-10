# Technical architecture — Pipsey

**Status:** Fully implemented, verified, and operational native macOS architecture (Feature Mode MVP verified on Apple Silicon).

## Component map
```text
+-----------------------------------------------------------------------------------+
| Native macOS Host (SwiftUI + AppKit nonactivating panel + Menu Bar)              |
| Dual Form Factors: Notch Island | Liquid Glass Floating Pod (Corner Snapping)     |
| Telescope HUD Mode (⌃⌥⌘) | Multi-Tier Sound Engine | Persistent Permission State  |
+-----------------------------------------+-----------------------------------------+
                                          |
                                 SessionCoordinator
                   (single authoritative lifecycle + session ID)
                  /                       |                         \
         CaptureService             SpeechService              EventRecorder
        ScreenCaptureKit           Apple STT/TTS               mouse timeline
               |                          |                          |
          FrameSampler          Timestamped transcript               |
               \                          |                         /
                +-------------- SessionEvidenceStore --------------+
                                          |
                             ObserverClient -> hosted VLM
                                          |
                            ObservationValidator (Schema)
                                          |
                           ConversationClient -> text LLM
                                          |
                      stream text + spoken answer -> UI / TTS
```

## Runtime responsibilities
**App shell:** SwiftUI views; AppKit nonactivating panel (`FloatingIslandPanel`) supporting dual form factors: (1) Notch Island anchored flush at top center (`Y = 0`) with Bezier ear curves, and (2) Liquid Glass Floating Pod with 3.2s ambient cyan breathing pulse, specular top rim highlight, magnetic corner snapping, and 30-second curiosity peeking loop. Includes multi-display placement, non-activating click-through outside interaction region, and exclusion from ScreenCaptureKit capture.

**SessionCoordinator:** actor / serial state owner, monotonically increasing session generation ID, concurrent lifecycle tasks, cancellation fan-out, recoverable failure mapping, bounded resource queues. No work starts from a view animation.

**PermissionCoordinator:** screen recording and microphone permission onboarding; required OS permissions tracked separately; deny/revoke behavior and settings guidance. Accessibility permission is optional for MVP event enhancement; never request it unnecessarily.

**CaptureService:** capture user-selected target using ScreenCaptureKit, bounded stream and optional short local replay file. Use host monotonic timestamps; record capture start, stop, displayed content size, scaling and window/display ID. Ensure screen recording actually started before showing “Recording”. Stop may require draining final buffers.

**EventRecorder:** cursor position and mouse button timing, not typed key values, passwords, clipboard contents or global keylogging. Target/event correlation is a hypothesis when only the cursor visually overlaps an element.

**SpeechService:** user microphone capture and speech recognition; partial/final transcript with monotonic time offsets; keyboard typed question fallback. Text-to-speech separated from microphone capture; avoid feedback loops by disabling/opening microphone carefully during spoken playback.

**FrameSampler:** decode or receive frames; sample uniform + event bursts; preserve frame-to-recording time mapping and content hashes. Deduplicate static frames, cap dimensions and count, add bounded backpressure. For very short transitions test burst rates well above 2 fps (not assumed sufficient).

**ObserverClient:** authenticated HTTPS adapter to user-configured small VLM endpoint. Input: frames + time offsets + non-sensitive mouse events + question context as untrusted data; output: strict versioned observations. Initially choose a candidate model by real compatibility/quality/latency tests, not name alone.

**EvidenceMerger:** validate frame IDs exist, times are in session, schema matches, no duplicated event IDs, and links remain stable. Separate observed visible changes from hypotheses and unknowns. Never equate a VLM's numeric confidence with calibrated accuracy.

**ConversationClient:** different, strong text LLM through a pluggable provider; receive only user question, bounded evidence, conversation history, and policy. May acknowledge “Show me the interaction” before visual evidence; no unsupported real-time narration. Stream partial text with proper cancellation and avoid claiming code provenance.

**Local retention:** private temporary files by default, ephemeral; explicitly selected session replay/export optional and local. No user-account backend/database for MVP. macOS Keychain for secrets, .env only for developer bootstrap placeholders.

## Time and causality
Every capture, transcript, click, observation and answer must reference session_id and monotonic time in milliseconds relative to capture start. Use monotonic clock for ordering, wall-clock for optional display only. If capture vs STT timestamps cannot be reconciled reliably, mark alignment approximate and block fine-grained claims. No inferred UI framework from video alone.

## Pipeline stages
1. Activation -> permission/preflight -> start ScreenCaptureKit + microphone concurrently -> confirm both statuses.
2. Show listening/recording; accumulate bounded stream, transcript and mouse metadata. Optional early STT acknowledgement is context-free.
3. Stop -> close streams, drain frames -> create immutable capture manifest.
4. Select sparse/burst frames -> invoke VLM with request ID and timeouts/retries only when side-effect safe.
5. Parse strict JSON, validate timestamp and frame references; downgrade malformed/unsupported observations to UNKNOWN, never fabricate.
6. Pass evidence to text LLM; stream textual and spoken answer. Keep citation-like frame pointers for optional review.
7. Follow-up conversation uses stored observation summary and source refs; user may request a new capture to disambiguate.

## Real-time strategy
UI states update immediately from local events. VLM may run on bounded frame windows during a live session if hosted throughput permits; initial milestone may analyze at Stop. Model B must not pretend to see live events before Model A provides evidence. Voice “I'm watching” can only mean capture is confirmed, not reasoning is done.

## Failure matrix
Permission denied: no capture, actionable settings link, no VLM request. Hotkey conflict: log locally and offer alternative gesture. Network offline: keep local capture private; safe retry with explicit user intent. Partial VLM result: render uncertainty; do not mark extraction complete. Cancel during upload: stop local work and cancel remote request where supported; late remote completions dropped by generation ID. App sleep/display switch: reconcile target, pause/stop with explicit UI warning. Model timeout: bounded backoff and visible error, no indefinite spinner.

## Hosting
Hosted inference is a provider adapter, not an entire cloud product. The user described near-free “ION” hosting but exact vendor, GPU SKU, quotas, and bandwidth are **unknown**. Probe upload/cold starts and total cost before deploying. Authenticate endpoints; avoid public anonymous inference; rate-limit and set concurrency limits; keep sensitive frame contents out of telemetry. Two logical models may run with independent providers.

## Performance and resource targets
Start with bounded local capture and a coarse 30-second ceiling; collect real M1 CPU, RSS, dropped-frame, STT, time-to-first-evidence, first-token and end-to-end timings. Make thresholds explicit only after first device measurements. Avoid spurious subsecond guarantees.

## Future changes
Debug Mode can reuse capture and conversation abstractions later, but requires explicit codebase access and security review; it must not influence first MVP architecture beyond sensible interfaces.
