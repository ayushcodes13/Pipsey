# Real-device evaluation plan

**Targets, not achieved results.** All tests must distinguish mock, real capture, hosted model and manually reviewed output.

## Ten canonical UI interactions
| ID | Demonstration | Main visible change | Common false claim |
| --- | --- | --- | --- |
| E01 | Hover dropdown | menu hidden → visible | says click rather than hover |
| E02 | Tooltip | label appears and disappears | invents text |
| E03 | Modal | dialog+backdrop opens on click | calls it navigation |
| E04 | Drag and drop | item/target changes | invents successful drop |
| E05 | Loading spinner | loading → result | claims completion early |
| E06 | Tab switch | selection and content change | invents data fetch |
| E07 | Sidebar expand | panel width/labels change | guesses exact easing |
| E08 | Carousel | visible slide changes | asserts unseen content |
| E09 | Toast | brief notification appears | misses transient event |
| E10 | Async list update | later content state changes | assumes backend details |

Use real window recordings from at least two applications, not only synthetic frames. Each fixture: sanitized recording ID, timestamp range, question, user action, expected visible transition, cited frame IDs, model response, human verdict and uncertainty.

## Scoring
Main transition detection: target **≥9/10** real cases. Every observation's frame IDs and timestamps must resolve to actual captured samples. No materially unobserved action may be asserted as fact in accepted explanations. Distinguish **observation, inference, unknown**. Trigger causality is generally inferred unless corroborated by event metadata. Low model-reported “confidence” is not a calibration guarantee.

## Test layers
1. Unit: state transitions, monotonic time, frame dedup, evidence validation, generation-ID cancellation.
2. Mocked integration: provider failures, malformed JSON, timeout, rate limit, partial transcript, retries.
3. Native M1: actual screenshot + microphone permissions; focus, hotkey, sleep, multi-display, Retina, CPU/RSS.
4. Model: actual small VLM on captured frames and separate text LLM on validated observation timeline.
5. Human review: inspect claim versus clip; annotate unsupported or contradictory explanations.

## Reliability and safety cases
Permission denied or revoked during recording; unintended display selection; password-manager window appears; app switched; zero-change clip; very short animation; recording auto-stop; cancel while uploading, inferring and speaking; network loss; malicious on-screen “ignore instructions” prompt; stale response from previous session.

## Metrics
Capture startup & stop/drain, dropped frames, STT time, upload bytes, frame count, VLM time, time to first text token, time to first audio, end-to-end p50/p95 after enough runs, idle/capture CPU/RSS on actual M1, API bill and cost per session. Publish measured values and test conditions, not guaranteed claims.

## Report format
Case ID | machine/OS | application | question | interaction | capture/frame timestamps | expected change | observed text | score/verdict | unsupported statements | error/cancel outcome | latency | cost | reviewer/date. Store private clips only in ignored app-private locations. Record non-sensitive summaries in PROGRESS.md.

**Shipping gate:** evaluation threshold, real-device full path and all security-critical tests verified. If agent has no M1, mark device-related cases BLOCKED and provide exact manual steps.
