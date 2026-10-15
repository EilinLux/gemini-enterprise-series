"""
Deploy DoubleClick Enterprise ADK Agent to Vertex AI Agent Engine (Part 2)

Reads configuration from the root `.env` file (`PROJECT_ID`, `REGION`, `APP_NAME`,
`GCS_BUCKET_SUFFIX`, `ADK_AGENT_DISPLAY_NAME`), wraps `root_agent` in `AdkApp`
with `enable_tracing=True`, and deploys to Vertex AI Agent Engine.
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load root .env
ROOT_DIR = Path(__file__).resolve().parents[2]
load_dotenv(ROOT_DIR / ".env")

PROJECT_ID = os.getenv("PROJECT_ID")
LOCATION = os.getenv("REGION", "europe-west1")
APP_NAME = os.getenv("APP_NAME", "double-click")
GCS_BUCKET_SUFFIX = os.getenv("GCS_BUCKET_SUFFIX", "docs-staging")
DISPLAY_NAME = os.getenv("ADK_AGENT_DISPLAY_NAME", "double-click-adk-concierge")
STAGING_BUCKET = f"gs://{PROJECT_ID}-{APP_NAME}-{GCS_BUCKET_SUFFIX}"


def deploy_to_agent_engine(dry_run: bool = False) -> None:
    from agents.adk_double_click_agent.agent import root_agent

    print("============================================================================")
    print(f"🚀 ADK Agent Engine Deployment — {DISPLAY_NAME}")
    print(f"   Project ID:      {PROJECT_ID}")
    print(f"   Location:        {LOCATION}")
    print(f"   Staging Bucket:  {STAGING_BUCKET}")
    print("============================================================================")

    if dry_run:
        print("✅ Dry-run check passed: root_agent loaded with tools:", [t.__name__ for t in root_agent.tools])
        return

    import vertexai
    from vertexai import agent_engines

    # 1. Initialize Vertex AI SDK with settings from .env
    vertexai.init(
        project=PROJECT_ID,
        location=LOCATION,
        staging_bucket=STAGING_BUCKET,
    )

    # 2. Wrap the ADK root_agent in an AdkApp object (with OpenTelemetry tracing enabled)
    app = agent_engines.AdkApp(
        agent=root_agent,
        enable_tracing=True,
    )

    # 3. Create / Deploy the managed Agent Engine instance
    remote_app = agent_engines.create(
        agent_engine=app,
        requirements=[
            "google-cloud-aiplatform[adk,agent_engines]>=1.111.0",
            "python-dotenv>=1.0.0",
        ],
        display_name=DISPLAY_NAME,
    )
    print(f"🎉 Deployed ADK Agent Engine Resource Name:\n   {remote_app.resource_name}")
    print("👉 Copy the resource name above into Gemini Enterprise -> '+ Add agent' -> 'Custom agent via Agent Engine'!")


if __name__ == "__main__":
    is_dry_run = "--dry-run" in sys.argv
    sys.path.insert(0, str(ROOT_DIR))
    deploy_to_agent_engine(dry_run=is_dry_run)
