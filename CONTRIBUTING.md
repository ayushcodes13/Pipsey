# Contributing to Pipsey

Pipsey is an independent, open-source native macOS companion designed to explain user-demonstrated software interactions. We value small verifiable improvements, kind collaboration and precise engineering claims.

## Start here
Read AGENTS.md, PRODUCT.md, ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, CHECKPOINTS.md and SECURITY.md. Pick an unverified milestone gate or a reproducible bug. Significant scope changes require discussion before implementation. Feature Mode is the sole MVP; Debug Mode and autonomous actions are future work.

## Pull requests
Please use a focused branch and include motivation, what changed, explicit build/test commands and observed results, real Mac/OS versions when relevant, error and cancellation paths, privacy and model cost impact, and updated CHECKPOINTS.md + PROGRESS.md. A mocked test is not a full system validation. Do not commit .env, keys, audio, screen captures or personal data.

## Code standards once source exists
Native SwiftUI/AppKit; small testable modules; bounded concurrency, cancellation ownership and evidence provenance. Add unit tests for state transitions and contracts; maintain manual integration tests on actual hardware. Prefer accessible design and restrained animations with reduced-motion support.

## Attribution
Repository code is MIT licensed unless a particular file or third-party asset says otherwise. Respect dependency and model licenses. Inspired by HeyClicky but not affiliated with it.

## Reporting vulnerabilities
Never publish private screenshots, credentials or exploit payloads in issues. Use a minimal non-sensitive issue asking for a private reporting channel until one is established. If secrets were pushed to Git, rotate them; don't assume deletion from latest branch removes them from history.
