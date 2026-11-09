# Development environment and runbook

**Current status: documentation-only. There are no real build/test commands because no Xcode/Swift application exists.** Replace these placeholders as source is implemented, with commands verified on the target Mac.

## Target
Apple Silicon M1 MacBook Air; no physical notch required. Determine macOS and Xcode versions on the machine, then choose compatible ScreenCaptureKit, SwiftUI/AppKit and Speech APIs. Don't promise unsupported APIs.

## First commands for M0 (recommended, not executed here)
```sh
sw_vers
xcodebuild -version
swift --version
git status --short --branch
git ls-files -s AGENTS.md CLAUDE.md
test -L CLAUDE.md && readlink CLAUDE.md
```

## Repo layout
The owner explicitly requested **no application folders during initial docs setup**. Root-level documents are deliberate. Implementing agent may add ordinary Xcode/Swift source and test directories in M0/M1 with rationale, not before.

## Configuration and secrets
Copy .env.example to local .env for experimental metadata only; .env is ignored. Never ship API keys in plaintext. The application should store actual BYOK model credentials in macOS Keychain. Service-owned secrets belong in host secret management. Hosted “ION” environment and model IDs remain unverified.

## Development process
Use branch-per-milestone PRs, keep shared session types owned by one agent, test with mocks and real M1 checks, store private samples outside Git, update CHECKPOINTS.md and PROGRESS.md with evidence, and ensure the README status reflects reality. Add a macOS CI workflow only after an actual build target exists; don't create fake tests for a documentation repo.

## Native permission checklist
Actual system settings for screen recording and microphone; denials and revocations; selected window/display; sleeping/locking Mac; multiple monitor scale; app capture self-exclusion; Accessibility only if the implemented feature truly requires it.

## Build/test command registry
- Native project build: `swift build --product Pipsey`
- Unit tests: `swift run PipseyTests`
- Native app execution: `.build/arm64-apple-macosx/debug/Pipsey`
- Real capture smoke test: `ScreenCaptureKit` authorization preflight via `PermissionCoordinator.shared.checkScreenRecordingStatus()`
- Visual model benchmark: In progress (M3 target)
- Release packaging: `swift build -c release --product Pipsey`

When implementing, replace each with actual Xcode scheme/destination, swift test (if used), test fixture setup, lint, run and release commands. Preserve failed output, never assert an unrun test passed.

## Performance
Benchmark M1 idle CPU/RSS, capture frames dropped, recording startup, STT latency, VLM sample/transport/inference, text first-token and TTS, p50/p95 full-flow. Keep cost in PROGRESS.md and user-approved provider cap.

## Troubleshooting guidance
If modifier-only gesture conflicts, use configurable standard chord. If screen/audio permissions denied, don't send a request. If model has insufficient frames, ask for redo instead of guessing. If cloud agent lacks Mac display or permissions, do safe code/test work and mark on-device gate BLOCKED, with exact validation steps.
