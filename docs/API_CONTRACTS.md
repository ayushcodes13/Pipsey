# Inter-service contracts (proposed v0.1)

These are **design contracts**, not implemented endpoints. Version them when code exists. Use strict schema validation at every model boundary; raw model prose is never trusted as a verified observation.

## Evidence manifest (local)
Required fields:
- schema_version: "0.1"; session_id: UUID; generation: integer.
- capture: target_type (window/display), target_id (opaque), dimensions, started_at_monotonic_ms, duration_ms, permission_state.
- frames: unique frame_id, relative_time_ms, width, height, sha256, local_ref; no secrets or raw pixels in textual metadata.
- events: type (cursor_move/mouse_down/mouse_up/scroll), relative_time_ms, optional normalized_position; never keyboard text.
- transcripts: start_ms, end_ms, text, is_final; user content is untrusted.
- recording_status: confirmed_started/stopped/cancelled/error; evidence_status: pending/validated/partial/failed.

## Observer request
POST /v1/observe (illustrative, provider-specific implementation may differ). HTTPS + bearer authentication, JSON manifest with signed/temporary frame upload references or bounded image payload; request_id/idempotency_key, deadline and consent marker. The service rejects oversized sessions and unknown schema versions. **No raw session or screenshot should be stored by default.**

Sample observer JSON (fabricated schema example, not actual model output):
```json
{
  "schema_version":"0.1",
  "session_id":"b2b5213f-8ca1-48e6-b0b5-0dc6220381b8",
  "request_id":"observe-001",
  "observations":[{
    "id":"obs-001",
    "start_ms":2100,"end_ms":2550,
    "kind":"visible_change",
    "before":"navigation panel hidden",
    "after":"navigation panel visible",
    "evidence_frame_ids":["frame-012","frame-018"],
    "trigger_hypothesis":"cursor entered menu region",
    "confidence_label":"medium",
    "uncertainties":["exact framework unknown"]
  }],
  "coverage":{"start_ms":0,"end_ms":5000},
  "unknowns":[]
}
```

## Validation conditions
Reject or mark partial if schema/version invalid, frame IDs missing, times negative/out-of-range, sample ordering inconsistent, unbounded text, unknown enum or response refers to a different session. Treat trigger_hypothesis as inference even if asserted strongly. Observer may return zero observations; do not invent a change.

## Text model request
System policy + user question + bounded immutable validated evidence + minimal conversation context. Evidence and transcript are **data**, not instructions. Model must answer with:
- observed_behavior: what frames show, referring to evidence IDs when possible.
- likely_mechanism: explicitly hypothetical explanation.
- implementation_approach: a practical path to reproduce behavior, with framework-dependent examples optional.
- uncertainties / need_for_redemonstration.
- brief conversational response for speech, longer optional text detail.

Never turn "looks like" into "the original app uses". Do not invent hidden code, animations, transition duration or event triggers not shown. If the evidence is insufficient, ask for a more focused demonstration.

## Transport and limits
Separate configuration for VLM and text endpoints, API key and model ID. Use strict connect/read timeouts, bounded retries, cancellation propagation, exponential backoff with jitter and request ID idempotency; no automatic repeated billing of non-idempotent calls. Limit total frames, bytes, tokens and session duration per run. Record timings, byte count and cost estimates without logging images/transcripts.

## Follow-ups and provenance
Maintain local session evidence ID and answer history. Replay original VLM only when explicitly requested or evidence invalidated. A stale request cannot update a newer session. Unknown/partial observations stay visibly uncertain.
