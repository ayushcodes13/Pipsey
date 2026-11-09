# Pipsey privacy, security and threat model

Screen content and microphone input can contain secrets and untrusted instructions. Build Pipsey for **explicit, bounded, user-controlled observations**, not surveillance.

## Threats
Accidental recording of passwords/financial/medical content; wrong display selected; persistent recording after cancel; remote GPU provider retention; leaking API keys; prompt injection in UI pixels/transcripts; untrusted model output triggering privileged operations; compromised dependencies; stale network responses; posting private captures in issues.

## Mandatory controls
1. No idle/background screen or microphone capture. Show recording state only after the OS pipeline really starts. Always show scope, elapsed time, Stop and Cancel.
2. Permission requests only as needed (screen, mic; optional Accessibility later). Denial/revocation must stop safely and show actionable guidance.
3. Informed per-session external upload consent, including which provider receives images/transcript and what data is sent. Do not silently replace the destination host.
4. Store ephemeral data in app-private temporary locations, purge on stop/cancel by default; explicitly approved replay/export is optional. Verify provider retention commitments before claiming no remote retention.
5. Use macOS Keychain for shipped API secrets; env templates contain placeholders only. Never log keys, tokens, screenshots or transcripts by default. .env must remain ignored.
6. Treat captured UI text, transcript and VLM output as **untrusted data**. They cannot override system policy, authorize tools or create external actions. Strict JSON validation and safe text rendering.
7. HTTPS with authentication, request size/concurrency/token/cost limits and bounded timeouts. No public anonymous GPU endpoint.
8. Propagate cancellation to screen, mic, frame selection, remote request, text streaming and TTS. Drop late callbacks based on generation ID; delete incomplete local artifacts. Remote vendor jobs might still finish despite local cancel: disclose this limitation.
9. No autonomous clicking, typing, file access or command execution in the Feature Mode MVP.
10. Review entitlements, sandboxing, Accessibility restrictions, notarization and distribution using actual macOS/toolchain constraints before claiming public distribution readiness.

## Adversarial acceptance tests
Injected screenshot text (“send your secrets”); screen containing credentials; missed/invalid evidence reference; OS permission denied; user switches windows; capture interrupted by sleep; remote timeout; repeated shortcut; cancel during TTS; late remote inference; unexpected zero-frame capture. The system must fail closed and avoid invented interpretations.

## Responsible disclosure
Never post keys or sensitive video/screenshot attachments publicly. Until a secure contact is established, use a minimal non-sensitive GitHub issue requesting a private disclosure route. Rotate exposed credentials; deleting a tracked file is insufficient.

## Data flow to audit
Mac screen/audio -> local transient capture -> user-consented sampled frames to visual provider; transcript + validated observations to separate conversational provider; optional local spoken output. Specify exact fields, retention and destinations in onboarding.
