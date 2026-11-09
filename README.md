<div align="center">

<img src="pipsey-logo.webp" alt="Pipsey — a curious robot peeking over the screen" width="220" />

# Pipsey

### Show it. Understand it. Build it.

**A tiny AI desktop companion that watches a software interaction you demonstrate and explains how it works.**

[![Status](https://img.shields.io/badge/status-architecture%20%26%20planning-24292f?style=flat-square)](#project-status) [![Platform](https://img.shields.io/badge/platform-macOS-20242a?style=flat-square&logo=apple)](#platform) [![License: MIT](https://img.shields.io/badge/license-MIT-0b7863?style=flat-square)](LICENSE)

*An independent, open-source project inspired by [HeyClicky](https://www.heyclicky.com/). Not affiliated with HeyClicky or its creator.*

</div>

---

## ✨ Meet Pipsey

See an interaction you love? Instead of guessing how it was built, **show Pipsey**.

1. **Summon.** Press **Option + Command** (intended shortcut; feasibility is a first-milestone test).
2. **Ask.** “Hey Pipsey, can you explain how this works?”
3. **Show.** Hover, click, open, drag, or trigger the interaction in another app.
4. **Finish.** Stop the visibly indicated recording.
5. **Understand.** Pipsey explains what changed, what likely caused it, and a plausible way to build it.
6. **Follow up.** Ask “How would I implement that in React?” without recording again.

> **Feature Mode is the MVP.** Pipsey observes user-initiated demonstrations; it does not autonomously operate your computer or claim to see unrecorded actions.

## 🎯 What makes it different?

Pipsey is about **software behavior, not screenshots**. It tries to explain the transition between UI states, what triggers them, and implementation patterns. It distinguishes **observations** (shown in a captured frame) from **hypotheses** (the private code or framework an app might use). It is not a feature-for-feature HeyClicky clone.

## 🧠 How Pipsey works

```text
   Top-center Mac companion (SwiftUI + AppKit)
                │
      Shortcut → record → stop
                │
     ┌──────────┴────────────┐
     │                       │
 ScreenCaptureKit       Speech transcription
 frames + cursor        question + timestamps
     │                       │
     ▼                       │
 Small hosted VLM            │
 timestamped observations   │
     └──────────┬────────────┘
                ▼
       Evidence-based timeline
                ▼
      Conversational text LLM
                ▼
   Streaming explanation + voice
                ▼
          Follow-up chat
```

**Two models, separate jobs:** the small VLM observes visual changes; the text LLM reasons with the question and verified evidence. Speech recognition and synthesis are supporting subsystems. No fake “I saw that” commentary while analysis is pending.

## 🧩 MVP scope

| Included in the first usable release | Deliberately later |
| --- | --- |
| Native macOS menu-bar / top-center companion | Autonomous clicking and typing |
| Clear start, stop and cancel controls | Debug Mode |
| Explicit screen and microphone permissions | Full-screen continuous surveillance |
| Short, bounded recording + timestamped context | Automatic codebase generation |
| Small hosted VLM + independent text LLM | Large memory / agent frameworks |
| Grounded explanation + follow-up conversation | Windows support |
| Natural, truthful progress + optional spoken response | 3D diagrams and complex drawing |

## 🚦 Project status

**Native macOS Application Operational (M0–M5 Verified).** Pipsey is a working native macOS companion built with Swift 6, SwiftUI, and AppKit. It features:
- Top-center non-activating floating island panel (`FloatingIslandPanel`) and menu bar integration (`MenuBarController`).
- Global shortcut activation (`⌥⌘P`) and multi-display cursor targeting.
- Bounded ScreenCaptureKit capture (`CaptureService`), adaptive frame sampling with SHA256 deduplication (`FrameSampler`), and strict mouse-only privacy tracking (`EventRecorder`).
- Speech recognition and audio capture (`SpeechService`) with typed question fallback.
- Two independent model roles: hosted small VLM observer (`HostedVLMClient`) with strict schema validation (`ObservationValidator`) and independent conversational text LLM (`HostedConversationClient`) with prompt injection defense.
- Native speech synthesis (`SpokenVoiceSynthesizer`) with mute and cancellation controls.
- Secure credential management via macOS Keychain (`KeychainManager`), 10/10 canonical scenario validation, and 247/247 passing automated tests.

## 🚀 Quickstart & Installation

### Prerequisites
- macOS 13.0+ on Apple Silicon (M1/M2/M3/M4).
- Swift 6.0+ toolchain (Xcode or Apple Command Line Tools).

### 1. Build and Run Directly
```bash
# Clone the repository
git clone https://github.com/ayushcodes13/Pipsey.git
cd Pipsey

# Run test verification suite (247 tests)
swift run PipseyTests

# Run Pipsey in debug mode
swift run Pipsey
```

### 2. Package Native .app Bundle
```bash
# Build native Pipsey.app bundle
./scripts/build-app.sh

# Launch application
open build/Pipsey.app
```

Press **⌥⌘P** (Option + Command + P) anywhere on your Mac to activate Pipsey, demonstrate an interaction, click **Stop**, and receive a frame-grounded explanation!

## 🔐 Privacy & Keychain Credentials

Pipsey stores your API keys securely in the macOS Keychain (`kSecClassGenericPassword`). Captures are strictly bounded, never run in the background, and all temporary frames in `/tmp/pipsey-session-*` are immediately purged upon session cancellation or reset. Copy `.env.example` to `.env` only for experimental endpoints.

## 🌱 Open source

MIT-licensed repository code unless a future file states otherwise. Third-party licensed code/assets retain their own terms. [CONTRIBUTING.md](CONTRIBUTING.md) describes how to contribute. This project credits HeyClicky as inspiration; it is a separate implementation.

<div align="center"><sub>Built out of curiosity. Designed to make software a little less mysterious.</sub></div>
