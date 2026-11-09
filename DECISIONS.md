# Architecture decisions (2026-11-09)

These are **locked product requirements** or **still-unverified engineering choices**. Log evidence and amendments through a PR.

| ID | Decision | Status | Verification |
| --- | --- | --- | --- |
| 001 | Feature Mode-only MVP, Debug Mode later | LOCKED | Owner decision |
| 002 | Native SwiftUI/AppKit shell | SELECTED | Must build on M1 |
| 003 | Top-center notch-style island | LOCKED UX | Non-notch Air fallback |
| 004 | Option+Command desired activation | UX LOCKED / TECH OPEN | Check modifier-only conflicts, fallback |
| 005 | Explicit bounded recording, stop/cancel | LOCKED | Real capture permission and teardown |
| 006 | ScreenCaptureKit | PROPOSED | macOS SDK and window capture tests |
| 007 | Small remote VLM + separate text LLM | LOCKED | Actual provider/model benchmarks |
| 008 | Qwen3-VL 2B first candidate | NOT SELECTED | Quality, API, host GPU and costs |
| 009 | Near-free “ION” hosting | UNRESOLVED | Identify exact provider/quotas |
| 010 | Apple speech recognition/TTS first | PROPOSED | Version and accuracy verification |
| 011 | Structured, frame-linked evidence timeline | LOCKED | Strict schema+provenance tests |
| 012 | No autonomous computer actions in MVP | LOCKED | Security |
| 013 | No DB/multi-user backend in MVP | LOCKED | Local sessions, optional inference endpoint |
| 014 | User-consented remote uploads/Keychain | LOCKED | Security review |
| 015 | Root-only initial docs/no app scaffolding | LOCKED FOR THIS PR | Owner request |
| 016 | Canonical AGENTS.md; CLAUDE.md symlink | LOCKED | Git mode 120000 |
| 017 | MIT-licensed project text | ADOPTED | Audit third-party dependencies/assets |
| 018 | Default Carbon hotkey ⌥⌘P with chord fallback | ADOPTED | Verified on M1 without Accessibility requirement |
| 019 | Model provider adapter protocol abstraction | ADOPTED | Decouples VLM/LLM from unverified "ION"; spend cap $0 |
| 020 | SPM Swift 6 executable architecture & test runner | ADOPTED | Verified with Swift 6.3.3 on macOS 27.2 SDK |

## Changes
### 2026-11-09 — M0 Feasibility & Preflight Decisions
- **ADR 018 (Hotkey):** Testing confirmed pure modifier-only `Option+Command` requires macOS Accessibility permission or `CGEventTap`. To honor the mandate "never request accessibility unnecessarily" and preserve product intent, Carbon `RegisterEventHotKey` was implemented with default chord `⌥⌘P` (Option+Command+P), retaining modifier-only monitoring as an opt-in mode when Accessibility is present.
- **ADR 019 (Model Hosting & ION):** Environment audit revealed "ION" hosting provider is unconfigured. Spend remains at $0. Provider adapter protocols (`ObserverClientProtocol`, `ConversationClientProtocol`) allow standard OpenAI-compatible endpoints, local models (vLLM/Ollama), or ION when explicitly provisioned.
- **ADR 020 (Toolchain & Scaffolding):** Host environment has Apple Command Line Tools 26.6 / Swift 6.3.3 and macOS 27.2 SDK. Swift Package Manager with `PipseyCore`, executable `Pipsey`, and standalone test harness `PipseyTests` selected and verified on target Apple M1 hardware.

## References
Apple ScreenCaptureKit: https://developer.apple.com/documentation/screencapturekit/
Apple AppKit: https://developer.apple.com/documentation/appkit/
Apple Speech: https://developer.apple.com/documentation/speech/
Original inspiration: https://github.com/farzaa/clicky
