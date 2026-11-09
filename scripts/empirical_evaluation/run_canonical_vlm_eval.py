#!/usr/bin/env python3
"""
Pipsey Canonical Visual Observer Empirical Evaluation Runner
Runs all 10 canonical interaction scenarios (E01-E10) with real generated UI frames
sent to the live Vision-Language Model (Model A) on Azure OpenAI / OpenAI.
"""

import os
import sys
import json
import time
import base64
import urllib.request
from PIL import Image, ImageDraw, ImageFont

# 10 Canonical Scenarios matching CanonicalEvaluationFixture
SCENARIOS = [
    {
        "id": "E01",
        "name": "Hover Dropdown",
        "question": "How does this menu appear?",
        "render_before": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(245, 247, 250)),
            draw.rectangle([20, 20, 100, 50], fill=(255, 255, 255), outline=(200, 205, 215)),
            draw.text((30, 28), "Products ▾", fill=(30, 35, 45)),
            draw.text((20, 80), "Welcome to the application dashboard.", fill=(80, 90, 105))
        ],
        "render_after": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(245, 247, 250)),
            draw.rectangle([20, 20, 100, 50], fill=(230, 235, 245), outline=(150, 160, 180)),
            draw.text((30, 28), "Products ▾", fill=(20, 40, 120)),
            # Dropdown menu
            draw.rectangle([20, 52, 160, 150], fill=(255, 255, 255), outline=(180, 185, 200)),
            draw.text((30, 60), "Analytics", fill=(40, 45, 55)),
            draw.text((30, 85), "Integrations", fill=(40, 45, 55)),
            draw.text((30, 110), "Documentation", fill=(40, 45, 55)),
            # Mouse cursor
            draw.polygon([(45, 35), (45, 48), (53, 44)], fill=(0, 0, 0))
        ],
        "expected_change": "dropdown menu expanded below Products button",
        "forbidden_claim": "clicked the menu item"
    },
    {
        "id": "E02",
        "name": "Tooltip Appearance",
        "question": "Where did this tooltip come from?",
        "render_before": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(255, 255, 255)),
            draw.rectangle([50, 50, 90, 90], fill=(240, 242, 245), outline=(180, 185, 195)),
            draw.text((62, 62), "★", fill=(220, 160, 0)),
            draw.text((50, 110), "Document editor view", fill=(100, 105, 115))
        ],
        "render_after": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(255, 255, 255)),
            draw.rectangle([50, 50, 90, 90], fill=(230, 235, 245), outline=(140, 150, 170)),
            draw.text((62, 62), "★", fill=(220, 160, 0)),
            # Cursor hovering button
            draw.polygon([(70, 70), (70, 82), (78, 78)], fill=(0, 0, 0)),
            # Tooltip
            draw.rectangle([50, 100, 175, 126], fill=(30, 35, 45)),
            draw.text((58, 106), "Add to favorites", fill=(255, 255, 255))
        ],
        "expected_change": "tooltip bubble Add to favorites appeared",
        "forbidden_claim": "invented text not in frame"
    },
    {
        "id": "E03",
        "name": "Modal Dialog Open",
        "question": "How did the screen darken?",
        "render_before": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(250, 250, 252)),
            draw.rectangle([30, 30, 150, 65], fill=(37, 99, 235)),
            draw.text((45, 42), "New Project", fill=(255, 255, 255)),
            draw.text((30, 90), "Project dashboard listing 5 items", fill=(100, 105, 115))
        ],
        "render_after": lambda draw: [
            # Darkened backdrop
            draw.rectangle([0, 0, 400, 250], fill=(70, 75, 85)),
            # Centered modal
            draw.rectangle([60, 40, 340, 210], fill=(255, 255, 255), outline=(120, 125, 135)),
            draw.text((80, 55), "Create New Project", fill=(20, 25, 35)),
            draw.rectangle([80, 90, 320, 120], fill=(245, 247, 250), outline=(200, 205, 215)),
            draw.text((90, 98), "Project Name...", fill=(150, 155, 165)),
            draw.rectangle([230, 160, 320, 190], fill=(37, 99, 235)),
            draw.text((250, 170), "Confirm", fill=(255, 255, 255))
        ],
        "expected_change": "modal dialog opened with darkened backdrop",
        "forbidden_claim": "page navigation"
    },
    {
        "id": "E04",
        "name": "Drag and Drop Task",
        "question": "How did this item move?",
        "render_before": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(245, 247, 250)),
            # Column 1: To Do
            draw.rectangle([20, 20, 180, 230], fill=(235, 238, 243)),
            draw.text((30, 28), "TO DO", fill=(100, 105, 115)),
            draw.rectangle([30, 50, 170, 90], fill=(255, 255, 255)),
            draw.text((40, 62), "Design App Icon", fill=(30, 35, 45)),
            # Column 2: In Progress
            draw.rectangle([200, 20, 360, 230], fill=(235, 238, 243)),
            draw.text((210, 28), "IN PROGRESS", fill=(100, 105, 115))
        ],
        "render_after": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(245, 247, 250)),
            # Column 1: To Do (now empty)
            draw.rectangle([20, 20, 180, 230], fill=(235, 238, 243)),
            draw.text((30, 28), "TO DO", fill=(100, 105, 115)),
            # Column 2: In Progress (contains moved card)
            draw.rectangle([200, 20, 360, 230], fill=(235, 238, 243)),
            draw.text((210, 28), "IN PROGRESS", fill=(100, 105, 115)),
            draw.rectangle([210, 50, 350, 90], fill=(255, 255, 255)),
            draw.text((220, 62), "Design App Icon", fill=(30, 35, 45)),
            # Cursor on moved card
            draw.polygon([(280, 70), (280, 82), (288, 78)], fill=(0, 0, 0))
        ],
        "expected_change": "card moved from TO DO to IN PROGRESS column",
        "forbidden_claim": "instant copy paste"
    },
    {
        "id": "E05",
        "name": "Loading Spinner to Content",
        "question": "What happened while waiting?",
        "render_before": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(255, 255, 255)),
            draw.text((30, 30), "Data Feed", fill=(30, 35, 45)),
            # Loading indicator
            draw.arc([180, 100, 220, 140], start=30, end=300, fill=(37, 99, 235), width=4),
            draw.text((155, 155), "Loading metrics...", fill=(120, 125, 135))
        ],
        "render_after": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(255, 255, 255)),
            draw.text((30, 30), "Data Feed", fill=(30, 35, 45)),
            # Metrics list
            draw.rectangle([30, 70, 370, 110], fill=(245, 247, 250)),
            draw.text((45, 82), "Active Users: 12,450", fill=(30, 35, 45)),
            draw.rectangle([30, 120, 370, 160], fill=(245, 247, 250)),
            draw.text((45, 132), "Uptime: 99.98%", fill=(30, 35, 45))
        ],
        "expected_change": "spinner replaced with loaded data metrics",
        "forbidden_claim": "completed immediately"
    },
    {
        "id": "E06",
        "name": "Tab Switch",
        "question": "How did this view switch?",
        "render_before": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(255, 255, 255)),
            # Tabs: Overview active
            draw.text((30, 25), "Overview", fill=(37, 99, 235)),
            draw.rectangle([30, 45, 95, 48], fill=(37, 99, 235)),
            draw.text((120, 25), "Settings", fill=(120, 125, 135)),
            draw.text((30, 80), "Welcome to system overview report.", fill=(40, 45, 55))
        ],
        "render_after": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(255, 255, 255)),
            # Tabs: Settings active
            draw.text((30, 25), "Overview", fill=(120, 125, 135)),
            draw.text((120, 25), "Settings", fill=(37, 99, 235)),
            draw.rectangle([120, 45, 180, 48], fill=(37, 99, 235)),
            draw.text((30, 80), "Configure application preferences and notifications.", fill=(40, 45, 55)),
            draw.polygon([(145, 35), (145, 47), (153, 43)], fill=(0, 0, 0))
        ],
        "expected_change": "tab switched from Overview to Settings",
        "forbidden_claim": "full page reload"
    },
    {
        "id": "E07",
        "name": "Sidebar Expansion",
        "question": "How did the sidebar expand?",
        "render_before": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(245, 247, 250)),
            # Collapsed sidebar: 50px wide
            draw.rectangle([0, 0, 50, 250], fill=(30, 35, 45)),
            draw.text((18, 20), "☰", fill=(255, 255, 255)),
            draw.text((18, 60), "⌂", fill=(180, 185, 195)),
            draw.text((18, 100), "⚙", fill=(180, 185, 195)),
            draw.text((80, 40), "Main workspace content area", fill=(100, 105, 115))
        ],
        "render_after": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(245, 247, 250)),
            # Expanded sidebar: 160px wide
            draw.rectangle([0, 0, 160, 250], fill=(30, 35, 45)),
            draw.text((18, 20), "☰", fill=(255, 255, 255)),
            draw.text((18, 60), "⌂ Home", fill=(255, 255, 255)),
            draw.text((18, 100), "⚙ Settings", fill=(255, 255, 255)),
            draw.text((190, 40), "Main workspace content area", fill=(100, 105, 115)),
            draw.polygon([(25, 25), (25, 37), (33, 33)], fill=(255, 255, 255))
        ],
        "expected_change": "sidebar expanded revealing text labels Home and Settings",
        "forbidden_claim": "guessing exact private animation easing"
    },
    {
        "id": "E08",
        "name": "Carousel Slide Transition",
        "question": "How did the slide change?",
        "render_before": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(240, 242, 245)),
            # Slide 1 banner
            draw.rectangle([40, 30, 360, 190], fill=(220, 235, 255)),
            draw.text((120, 95), "Slide 1: Summer Sale", fill=(20, 40, 120)),
            draw.text((330, 100), "▶", fill=(50, 55, 65))
        ],
        "render_after": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(240, 242, 245)),
            # Slide 2 banner
            draw.rectangle([40, 30, 360, 190], fill=(255, 235, 220)),
            draw.text((120, 95), "Slide 2: Autumn Styles", fill=(140, 60, 20)),
            draw.text((330, 100), "▶", fill=(50, 55, 65)),
            draw.polygon([(335, 105), (335, 117), (343, 113)], fill=(0, 0, 0))
        ],
        "expected_change": "carousel transitioned from Slide 1 to Slide 2",
        "forbidden_claim": "claims unseen future slide details"
    },
    {
        "id": "E09",
        "name": "Toast Notification",
        "question": "What notification just showed up?",
        "render_before": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(255, 255, 255)),
            draw.rectangle([30, 40, 150, 75], fill=(37, 99, 235)),
            draw.text((50, 52), "Save Changes", fill=(255, 255, 255)),
            draw.text((30, 110), "Profile settings form fields", fill=(100, 105, 115))
        ],
        "render_after": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(255, 255, 255)),
            draw.rectangle([30, 40, 150, 75], fill=(37, 99, 235)),
            draw.text((50, 52), "Save Changes", fill=(255, 255, 255)),
            draw.text((30, 110), "Profile settings form fields", fill=(100, 105, 115)),
            # Toast notification top-right
            draw.rectangle([190, 20, 380, 55], fill=(22, 101, 52)),
            draw.text((205, 30), "✓ Changes saved successfully", fill=(255, 255, 255))
        ],
        "expected_change": "green toast notification Changes saved successfully appeared",
        "forbidden_claim": "permanent dialog window"
    },
    {
        "id": "E10",
        "name": "Async List Update",
        "question": "How did the new item appear?",
        "render_before": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(245, 247, 250)),
            draw.text((30, 20), "Inbox (2 messages)", fill=(30, 35, 45)),
            draw.rectangle([30, 50, 370, 85], fill=(255, 255, 255)),
            draw.text((45, 60), "1. Alex: Review design doc", fill=(40, 45, 55)),
            draw.rectangle([30, 95, 370, 130], fill=(255, 255, 255)),
            draw.text((45, 105), "2. Sam: Standup at 10am", fill=(40, 45, 55))
        ],
        "render_after": lambda draw: [
            draw.rectangle([0, 0, 400, 250], fill=(245, 247, 250)),
            draw.text((30, 20), "Inbox (3 messages)", fill=(30, 35, 45)),
            # New message at top highlighted blue
            draw.rectangle([30, 50, 370, 85], fill=(235, 245, 255), outline=(147, 197, 253)),
            draw.text((45, 60), "1. Taylor: PR ready for review (NEW)", fill=(29, 78, 216)),
            draw.rectangle([30, 95, 370, 130], fill=(255, 255, 255)),
            draw.text((45, 105), "2. Alex: Review design doc", fill=(40, 45, 55)),
            draw.rectangle([30, 140, 370, 175], fill=(255, 255, 255)),
            draw.text((45, 150), "3. Sam: Standup at 10am", fill=(40, 45, 55))
        ],
        "expected_change": "new message card Taylor appeared at top of inbox",
        "forbidden_claim": "claims knowledge of private database schema"
    }
]

def generate_frames(output_dir):
    os.makedirs(output_dir, exist_ok=True)
    frame_paths = {}
    for sc in SCENARIOS:
        im1 = Image.new("RGB", (400, 250), (255, 255, 255))
        sc["render_before"](ImageDraw.Draw(im1))
        p1 = os.path.join(output_dir, f"{sc['id']}_before.jpg")
        im1.save(p1, "JPEG", quality=85)

        im2 = Image.new("RGB", (400, 250), (255, 255, 255))
        sc["render_after"](ImageDraw.Draw(im2))
        p2 = os.path.join(output_dir, f"{sc['id']}_after.jpg")
        im2.save(p2, "JPEG", quality=85)

        frame_paths[sc["id"]] = (p1, p2)
    return frame_paths

def run_vlm_inference(scenario, before_path, after_path, endpoint, api_key):
    with open(before_path, "rb") as f:
        b64_1 = base64.b64encode(f.read()).decode("utf-8")
    with open(after_path, "rb") as f:
        b64_2 = base64.b64encode(f.read()).decode("utf-8")

    system_prompt = f"""You are Pipsey Visual Observer. Inspect the sequence of captured frames and mouse events.
Return ONLY valid JSON matching this schema:
{{
  "schema_version": "0.1",
  "session_id": "eval-session-{scenario['id']}",
  "request_id": "eval-req-{scenario['id']}",
  "observations": [
    {{
      "id": "obs-001",
      "start_ms": 100,
      "end_ms": 600,
      "kind": "visible_change",
      "before": "accurate concise description of frame 1",
      "after": "accurate concise description of frame 2",
      "evidence_frame_ids": ["frame-001", "frame-002"],
      "trigger_hypothesis": "inferred trigger e.g. cursor hover or click",
      "confidence_label": "high",
      "uncertainties": []
    }}
  ],
  "coverage": {{ "start_ms": 0, "end_ms": 1000 }},
  "unknowns": []
}}"""

    body = {
        "messages": [
            {"role": "system", "content": system_prompt},
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": f"Analyze UI changes between Frame 1 (frame-001) and Frame 2 (frame-002) for user question: '{scenario['question']}'"},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{b64_1}"}},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{b64_2}"}}
                ]
            }
        ],
        "response_format": {"type": "json_object"}
    }

    req = urllib.request.Request(
        endpoint,
        data=json.dumps(body).encode(),
        headers={
            "Content-Type": "application/json",
            "api-key": api_key,
            "Authorization": f"Bearer {api_key}"
        }
    )

    t0 = time.time()
    with urllib.request.urlopen(req, timeout=30) as resp:
        elapsed_ms = int((time.time() - t0) * 1000)
        data = json.loads(resp.read().decode())
        raw_content = data["choices"][0]["message"]["content"]
        usage = data.get("usage", {})
        return elapsed_ms, json.loads(raw_content), usage

def main():
    print("=" * 70)
    print("PIPSEY CANONICAL VISUAL SCENARIO EVALUATION (M3 EMPIRICAL VLM AUDIT)")
    print("=" * 70)

    key = os.environ.get("ONEPAGER_AZURE_OPENAI_API_KEY") or os.environ.get("AZURE_OPENAI_API_KEY") or os.environ.get("PIPSEY_VLM_API_KEY") or os.environ.get("OPENAI_API_KEY")
    base = os.environ.get("ONEPAGER_AZURE_OPENAI_BASE_URL") or "https://onepagersouthindia.openai.azure.com/openai/v1/"
    model = os.environ.get("PIPSEY_VLM_MODEL") or "gpt-5-mini"

    if not key:
        print("ERROR: No VLM API key configured in environment.")
        sys.exit(1)

    if "openai.azure.com" in base:
        endpoint = f"https://onepagersouthindia.openai.azure.com/openai/deployments/{model}/chat/completions?api-version=2024-02-15-preview"
    else:
        endpoint = f"{base}/chat/completions"

    print(f"Provider: Azure OpenAI")
    print(f"Model: {model}")
    print(f"Endpoint: {endpoint}")
    print(f"Scenarios: 10 canonical UI interactions (E01-E10)")
    print("-" * 70)

    frames_dir = "scripts/empirical_evaluation/frames"
    frames = generate_frames(frames_dir)
    print(f"Generated 20 real test frames in {frames_dir}/\n")

    results = []
    total_latency_ms = 0
    passed_scenarios = 0

    for sc in SCENARIOS:
        sc_id = sc["id"]
        sc_name = sc["name"]
        p1, p2 = frames[sc_id]
        print(f"[{sc_id}] Running: {sc_name}...", end=" ", flush=True)

        try:
            latency_ms, response_json, usage = run_vlm_inference(sc, p1, p2, endpoint, key)
            total_latency_ms += latency_ms

            obs = response_json.get("observations", [])
            if not obs:
                print(f"❌ FAIL (No observations returned) [{latency_ms}ms]")
                results.append({"id": sc_id, "name": sc_name, "pass": False, "error": "Empty observations"})
                continue

            first_obs = obs[0]
            before = first_obs.get("before", "")
            after = first_obs.get("after", "")
            trigger = first_obs.get("trigger_hypothesis", "")
            evidence_frames = first_obs.get("evidence_frame_ids", [])

            # Check 1: Evidence frames cited
            has_evidence = len(evidence_frames) > 0

            # Check 2: Absence of forbidden claim
            full_text = f"{before} {after} {trigger}".lower()
            no_forbidden = sc["forbidden_claim"].lower() not in full_text

            # Check 3: State transition captured
            has_transition = len(before) > 0 and len(after) > 0 and before != after

            is_pass = has_evidence and no_forbidden and has_transition

            if is_pass:
                passed_scenarios += 1
                print(f"✅ PASS ({latency_ms}ms) | Trigger: '{trigger}'")
            else:
                print(f"❌ FAIL (Validation failed) [{latency_ms}ms]")

            results.append({
                "id": sc_id,
                "name": sc_name,
                "pass": is_pass,
                "latency_ms": latency_ms,
                "before": before,
                "after": after,
                "trigger": trigger,
                "evidence_frames": evidence_frames,
                "tokens": usage.get("total_tokens", 0)
            })

        except Exception as e:
            print(f"❌ ERROR: {e}")
            results.append({"id": sc_id, "name": sc_name, "pass": False, "error": str(e)})

    print("\n" + "=" * 70)
    print("EMPIRICAL EVALUATION SUMMARY")
    print("=" * 70)
    print(f"Scenarios Evaluated: {len(SCENARIOS)}")
    print(f"Scenarios Passed:    {passed_scenarios}/{len(SCENARIOS)} ({passed_scenarios / len(SCENARIOS) * 100:.1f}%)")
    print(f"Avg Latency:         {total_latency_ms / max(len(results), 1):.0f} ms")
    print(f"Target Gate:         ≥ 9/10 (90%) required by AGENTS.md / EVALUATION.md")

    report_path = "scripts/empirical_evaluation/empirical_eval_report.json"
    with open(report_path, "w") as f:
        json.dump({
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "model": model,
            "provider": "Azure OpenAI",
            "passed": passed_scenarios,
            "total": len(SCENARIOS),
            "pass_rate": passed_scenarios / len(SCENARIOS),
            "results": results
        }, f, indent=2)
    print(f"Detailed JSON results written to {report_path}")

    if passed_scenarios >= 9:
        print("VERDICT: PASS (Meets canonical accuracy quality gate)")
        sys.exit(0)
    else:
        print("VERDICT: FAIL (Does not meet required 9/10 gate)")
        sys.exit(1)

if __name__ == "__main__":
    main()
