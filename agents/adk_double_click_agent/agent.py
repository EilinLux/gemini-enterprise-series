"""
DoubleClick Enterprise — Code-First ADK Agent (Part 2: Conversational Modeling)

This module defines the `root_agent` for DoubleClick Enterprise using the Google
Agent Development Kit (ADK). It includes tools to query project statuses from
our Part 1 dataset and calculate Acme Corp renewal discounts.
"""

import os
from typing import Any
from dotenv import load_dotenv

load_dotenv()

GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-pro")
APP_NAME = os.getenv("APP_NAME", "double-click")
COMPANY_NAME = os.getenv("COMPANY_NAME", "DoubleClick Enterprise")


def lookup_double_click_project_status(project_name: str) -> dict[str, Any]:
    """Looks up the operational status, owner, budget, and summary of a DoubleClick Enterprise project.

    Args:
        project_name: Name of the internal project (e.g., 'Double-click', 'Phoenix', 'Alpha').

    Returns:
        A dictionary containing the project's status, owner_email, budget_usd, and summary.
    """
    catalog = {
        "double-click": {
            "project_id": "PRJ-001",
            "project_name": "Double-click",
            "status": "ACTIVE",
            "owner_email": "zelda@doubleclick.example.com",
            "budget_usd": 450000,
            "summary": "Enterprise AI Agent platform rollout on Gemini Enterprise with Graph RAG and ADK.",
        },
        "phoenix": {
            "project_id": "PRJ-002",
            "project_name": "Phoenix",
            "status": "ON_HOLD",
            "owner_email": "alex@doubleclick.example.com",
            "budget_usd": 280000,
            "summary": "Legacy Oracle ERP migration to Google Cloud Private Service Connect (PSC).",
        },
        "alpha": {
            "project_id": "PRJ-003",
            "project_name": "Alpha",
            "status": "DELAYED",
            "owner_email": "marco@doubleclick.example.com",
            "budget_usd": 195000,
            "summary": "Omni-channel retail POS integration delayed 14 days by CloudNet Hardware Ltd.",
        },
    }
    key = project_name.strip().lower()
    if key in catalog:
        return {"found": True, "project": catalog[key]}
    return {
        "found": False,
        "message": f"No project named '{project_name}' found in DoubleClick Enterprise portfolio.",
    }


def calculate_acme_renewal_discount(current_acv_usd: float, seat_expansion_percent: float) -> dict[str, Any]:
    """Calculates the renewal ACV and volume discount per DoubleClick Enterprise MSA terms.

    Per CTR-ACME-2026-089: If a client expands seat licenses by >= 25% prior to their
    Renewal Date, a 15% Enterprise Tier volume discount applies.

    Args:
        current_acv_usd: Current Annual Contract Value in USD (e.g., 420000.0).
        seat_expansion_percent: Percentage increase in Gemini Enterprise seats (e.g., 25.0).

    Returns:
        Dictionary with discount eligibility, discount_rate, and final_renewal_acv_usd.
    """
    eligible = seat_expansion_percent >= 25.0
    discount_rate = 0.15 if eligible else 0.0
    final_acv = round(current_acv_usd * (1.0 - discount_rate), 2)
    return {
        "eligible_for_enterprise_discount": eligible,
        "discount_rate_percent": discount_rate * 100,
        "original_acv_usd": current_acv_usd,
        "final_renewal_acv_usd": final_acv,
        "policy_reference": "CTR-ACME-2026-089 Section 3 (Termination & Renewal Clauses)",
    }


try:
    from google.adk.agents import Agent

    root_agent = Agent(
        name="double_click_adk_concierge",
        model=GEMINI_MODEL,
        description=(
            f"Official {COMPANY_NAME} ADK Concierge Agent for checking internal project "
            "statuses and calculating enterprise contract renewal discounts."
        ),
        instruction=f"""You are the {COMPANY_NAME} AI Concierge ('{APP_NAME}').
        1. Use `lookup_double_click_project_status` whenever a user asks about the status, owner, or blockers of internal projects (such as Double-click, Phoenix, or Alpha).
        2. Use `calculate_acme_renewal_discount` whenever an Account Executive asks to calculate contract renewal pricing or volume discounts.
        3. Always cite the policy or contract reference returned by your tools.""",
        tools=[lookup_double_click_project_status, calculate_acme_renewal_discount],
    )
except ImportError:
    # Lightweight fallback so local unit tests can still inspect `root_agent` metadata
    # even before `google-cloud-aiplatform[adk,agent_engines]` is installed.
    class _FallbackAgent:
        name = "double_click_adk_concierge"
        model = GEMINI_MODEL
        tools = [lookup_double_click_project_status, calculate_acme_renewal_discount]

    root_agent = _FallbackAgent()
