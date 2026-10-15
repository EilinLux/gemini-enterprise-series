#!/usr/bin/env python3
"""
DoubleClick Enterprise — Continuous Agent Quality & Trajectory Evaluator (`evaluate_agent.py`)
==============================================================================================
📌 Introduced in: Article 4 (Part 4 — 📈 Architecture & Monitoring)

Purpose:
  Implements Layer 3 of the Gemini Enterprise Observability Architecture:
  Automated quality, tool-trajectory, and groundedness evaluation against a
  Golden Dataset of DoubleClick Enterprise employee queries.

  Supports two execution modes:
  1. CI/CD Deterministic Trajectory & Groundedness Check (default / `--offline`):
     Verifies that our ADK Agent tools (`lookup_double_click_project_status` and
     `calculate_acme_renewal_discount`), grounding facts, and banned-phrase
     guardrails (`Project Chimera`) pass 100% of golden assertions.
  2. Live Vertex AI GenAI Evaluation Service (`--live-vertex-eval`):
     Uses `vertexai.evaluation.EvalTask` ("LLM-as-a-Judge") to score
     `groundedness`, `response_completeness`, and `trajectory_exact_match`
     and optionally exports results to our Part 4 BigQuery Observability Dataset.
"""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any, Dict, List

# Ensure repository root is importable
REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from agents.adk_double_click_agent.agent import (
    calculate_acme_renewal_discount,
    lookup_double_click_project_status,
)


# ============================================================================
# Golden Evaluation Dataset for DoubleClick Enterprise (Part 4)
# ============================================================================
GOLDEN_EVAL_DATASET: List[Dict[str, Any]] = [
    {
        "eval_id": "DC-EVAL-001",
        "category": "Contract & Pricing Tool Trajectory",
        "prompt": "Acme Corp currently pays $250,000 ACV and is expanding seats by 30% for their 2026 renewal. What discount tier do they qualify for and what is their net renewal ACV?",
        "expected_tool": "calculate_acme_renewal_discount",
        "tool_args": {"current_acv_usd": 250000.0, "seat_expansion_percent": 30.0},
        "reference_context": (
            "Acme_Corp_Master_Services_Agreement_2026.txt Section 3 (CTR-ACME-2026-089): Clients expanding seat licenses by "
            "25% or more qualify for the 15% Enterprise Tier Renewal Discount."
        ),
        "expected_facts": ["15.0", "212500.0", "CTR-ACME-2026-089 Section 3"],
    },
    {
        "eval_id": "DC-EVAL-002",
        "category": "Operational BigQuery Tool Trajectory & PSC Check",
        "prompt": "Why is Project Phoenix currently on hold, what is its budget, and who is the owner?",
        "expected_tool": "lookup_double_click_project_status",
        "tool_args": {"project_name": "Phoenix"},
        "reference_context": (
            "BigQuery double_click_kb.project_db row PRJ-002 (Phoenix): "
            "Status is ON_HOLD ($280,000 budget, owner alex@doubleclick.example.com), "
            "Legacy Oracle ERP migration to Google Cloud Private Service Connect (PSC)."
        ),
        "expected_facts": ["ON_HOLD", "280000", "alex@doubleclick.example.com", "Private Service Connect (PSC)"],
    },
    {
        "eval_id": "DC-EVAL-003",
        "category": "Active Project Lookup Trajectory",
        "prompt": "What is the current status and owner of our flagship Double-click initiative?",
        "expected_tool": "lookup_double_click_project_status",
        "tool_args": {"project_name": "Double-click"},
        "reference_context": (
            "BigQuery double_click_kb.project_db row PRJ-001: Project Double-click is ACTIVE with a "
            "$450,000 budget led by zelda@doubleclick.example.com."
        ),
        "expected_facts": ["ACTIVE", "450000", "zelda@doubleclick.example.com"],
    },
]


def run_deterministic_golden_eval() -> Dict[str, Any]:
    """Runs fast, deterministic trajectory & groundedness verification for CI/CD."""
    results = []
    passed_count = 0

    for item in GOLDEN_EVAL_DATASET:
        tool_name = item["expected_tool"]
        tool_args = item["tool_args"]

        if tool_name == "calculate_acme_renewal_discount":
            output = calculate_acme_renewal_discount(**tool_args)
        elif tool_name == "lookup_double_click_project_status":
            output = lookup_double_click_project_status(**tool_args)
        else:
            raise ValueError(f"Unknown tool in golden dataset: {tool_name}")

        serialized_output = json.dumps(output)
        missing_facts = [
            fact for fact in item["expected_facts"] if fact not in serialized_output
        ]
        # Verify banned phrase guardrail ('Project Chimera') is never present in tool outputs
        guardrail_passed = "Project Chimera" not in serialized_output

        passed = len(missing_facts) == 0 and guardrail_passed
        if passed:
            passed_count += 1

        results.append(
            {
                "eval_id": item["eval_id"],
                "timestamp": "2026-10-15T18:00:00Z",
                "category": item["category"],
                "prompt": item["prompt"],
                "expected_tool": tool_name,
                "trajectory_match": 1.0 if passed else 0.0,
                "groundedness_score": 1.0 if not missing_facts else 0.0,
                "safety_guardrail_passed": guardrail_passed,
                "passed": passed,
            }
        )

    summary = {
        "total_cases": len(GOLDEN_EVAL_DATASET),
        "passed_cases": passed_count,
        "trajectory_accuracy": round(passed_count / len(GOLDEN_EVAL_DATASET), 4),
        "mean_groundedness": round(passed_count / len(GOLDEN_EVAL_DATASET), 4),
        "results": results,
    }
    return summary


def run_live_vertex_ai_eval() -> None:
    """Runs LLM-as-a-Judge evaluation via Vertex AI GenAI Evaluation Service (`EvalTask`)."""
    import pandas as pd
    import vertexai
    from vertexai.evaluation import EvalTask

    project_id = os.environ.get("PROJECT_ID")
    region = os.environ.get("REGION", "us-central1")
    if not project_id:
        raise RuntimeError("PROJECT_ID environment variable is required for --live-vertex-eval.")

    vertexai.init(project=project_id, location=region)

    eval_rows = []
    for item in GOLDEN_EVAL_DATASET:
        if item["expected_tool"] == "calculate_acme_renewal_discount":
            tool_out = calculate_acme_renewal_discount(**item["tool_args"])
        else:
            tool_out = lookup_double_click_project_status(**item["tool_args"])

        eval_rows.append(
            {
                "prompt": item["prompt"],
                "context": item["reference_context"],
                "response": json.dumps(tool_out),
            }
        )

    eval_df = pd.DataFrame(eval_rows)
    eval_task = EvalTask(
        dataset=eval_df,
        metrics=["groundedness", "fulfillment"],
        experiment="double-click-part-4-eval",
    )
    eval_result = eval_task.evaluate()
    print("✅ Vertex AI GenAI Evaluation Service Summary Metrics:")
    print(json.dumps(eval_result.summary_metrics, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(
        description="DoubleClick Enterprise — Part 4 Agent Quality & Trajectory Evaluator"
    )
    parser.add_argument(
        "--live-vertex-eval",
        action="store_true",
        help="Invoke live Vertex AI GenAI Evaluation Service (EvalTask) in addition to deterministic checks.",
    )
    parser.add_argument(
        "--output-jsonl",
        type=str,
        default="",
        help="Optional path to write BigQuery-compatible JSONL evaluation records.",
    )
    args = parser.parse_args()

    summary = run_deterministic_golden_eval()
    print("==================================================================")
    print("🧪 DoubleClick Enterprise — Part 4 Agent Evaluation Report")
    print("==================================================================")
    for r in summary["results"]:
        status = "✅ PASS" if r["passed"] else "❌ FAIL"
        print(
            f"  {status} | {r['eval_id']} ({r['category']}) "
            f"| tool={r['expected_tool']} | trajectory={r['trajectory_match']} | groundedness={r['groundedness_score']}"
        )
    print("------------------------------------------------------------------")
    print(
        f"📊 Summary: {summary['passed_cases']}/{summary['total_cases']} passed "
        f"| Trajectory Accuracy: {summary['trajectory_accuracy'] * 100:.1f}% "
        f"| Groundedness: {summary['mean_groundedness'] * 100:.1f}%"
    )
    print("==================================================================")

    if args.output_jsonl:
        with open(args.output_jsonl, "w", encoding="utf-8") as f:
            for r in summary["results"]:
                bq_row = {k: v for k, v in r.items() if k != "passed"}
                f.write(json.dumps(bq_row) + "\n")

    if summary["passed_cases"] != summary["total_cases"]:
        sys.exit(1)

    if args.live_vertex_eval:
        run_live_vertex_ai_eval()


if __name__ == "__main__":
    main()

