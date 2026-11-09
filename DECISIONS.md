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

## Changes
Append date, proposal, alternatives, measured evidence, security/cost impact, decision and PR link. Never silently switch providers/models. Avoid unproven performance guarantees (“16ms grounding”, “subsecond VLM”, “free GPU all day”).

## References
Apple ScreenCaptureKit: https://developer.apple.com/documentation/screencapturekit/
Apple AppKit: https://developer.apple.com/documentation/appkit/
Apple Speech: https://developer.apple.com/documentation/speech/
Original inspiration: https://github.com/farzaa/clicky
