# Development environment and runbook

**Current status: Fully implemented and verified on macOS Apple Silicon (M0–M5).**

## Target
Apple Silicon M1 MacBook Air; no physical notch required. ScreenCaptureKit, SwiftUI/AppKit and Speech APIs.

## Repo layout
- `Sources/Pipsey/`: Main macOS application shell, SwiftUI companion island, and AppKit lifecycle.
- `Sources/PipseyCore/`: Core frameworks (Capture, Events, Speech, Observer, Conversation, Security, State).
- `Sources/PipseyTests/`: Verification and contract test suite.
- `docs/`: Technical specifications, ADRs, PRD, and engineering logs.
- `Assets/`: Vector brand assets, icons, and `AppIcon.icns`.
- `scripts/`: Packaging (`build-app.sh`), asset generation, and empirical VLM benchmarks.

## Configuration and secrets
Copy .env.example to local .env for experimental metadata only; .env is ignored. The application stores actual BYOK model credentials in macOS Keychain with `LAContext.interactionNotAllowed = true`.

## Development process
Use branch-per-milestone PRs, test with unit and real M1 checks, store private samples outside Git, update `docs/CHECKPOINTS.md` and `docs/PROGRESS.md` with evidence, and ensure the README status reflects reality.

## Build/test command registry
- Native project build: `swift build --product Pipsey`
- Unit tests: `swift run PipseyTests`
- Run offline verification suite: `swift build --build-tests && .build/debug/PipseyTests`
- Run live two-model network suite: `PIPSEY_RUN_LIVE_NETWORK_TESTS=1 .build/debug/PipseyTests`
- Package native `.app` bundle: `./scripts/build-app.sh`
- Launch packaged bundle: `open build/Pipsey.app`

When implementing, replace each with actual Xcode scheme/destination, swift test (if used), test fixture setup, lint, run and release commands. Preserve failed output, never assert an unrun test passed.

## Performance
Benchmark M1 idle CPU/RSS, capture frames dropped, recording startup, STT latency, VLM sample/transport/inference, text first-token and TTS, p50/p95 full-flow. Keep cost in PROGRESS.md and user-approved provider cap.

## Troubleshooting guidance
If modifier-only gesture conflicts, use configurable standard chord. If screen/audio permissions denied, don't send a request. If model has insufficient frames, ask for redo instead of guessing. If cloud agent lacks Mac display or permissions, do safe code/test work and mark on-device gate BLOCKED, with exact validation steps.
