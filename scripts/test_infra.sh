#!/usr/bin/env bash
# ============================================================================
# Gemini Enterprise Series — Automated Verification & Testing Suite
# Branch: 05-integration-and-security (Complete 5-Part Enterprise Stack)
# ============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "============================================================================"
echo "🧪 Running Repository Verification Suite — Branch 05 (Integration & Security)"
echo "============================================================================"

# 1. Verify .env.example has all required Part 1–5 keys
echo "1️⃣  Checking .env.example configuration keys (Parts 1–5)..."
REQUIRED_KEYS=(
  "PROJECT_ID"
  "REGION"
  "DISCOVERY_ENGINE_LOCATION"
  "APP_NAME"
  "COMPANY_NAME"
  "BQ_DATASET_ID"
  "GCS_BUCKET_SUFFIX"
  "DIALOGFLOW_TIME_ZONE"
  "DIALOGFLOW_DEFAULT_LANGUAGE"
  "ADK_AGENT_DISPLAY_NAME"
  "GEMINI_MODEL"
  "COMPANY_LOGO_URL"
  "SHORTCUT_TITLE"
  "SHORTCUT_URL"
  "ALLOWLISTED_DOMAINS"
  "BQ_LOGS_DATASET_ID"
  "GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY"
  "OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT"
  "ENABLE_WORKFORCE_IDENTITY"
  "WORKFORCE_POOL_ID"
  "OAUTH_ACTION_SECRET_ID"
  "PORTAL_PORT"
)

for key in "${REQUIRED_KEYS[@]}"; do
  if ! grep -q "^${key}=" "${ROOT_DIR}/.env.example"; then
    echo "❌ Missing required key in .env.example: ${key}"
    exit 1
  fi
done
echo "   ✅ All required .env keys present."

# 2. Verify Part 1 DoubleClick sample data files
echo "2️⃣  Validating DoubleClick Enterprise sample data files..."
for doc in WFH_Policy_Update_V2.txt Acme_Corp_Master_Services_Agreement_2026.txt IT_Security_Onboarding_Playbook.txt; do
  [[ -s "${ROOT_DIR}/data/unstructured/${doc}" ]] || { echo "❌ Missing ${doc}"; exit 1; }
done
echo "   ✅ Part 1 Unstructured & Structured data files verified."

# 3. Test Part 2 ADK Agent tools & A2A JSON Agent Card
echo "3️⃣  Testing Part 2 ADK Python Agent tools & A2A JSON Agent Card..."
python3 -c '
import json, sys
sys.path.insert(0, sys.argv[1])
from agents.adk_double_click_agent.agent import (
    lookup_double_click_project_status,
    calculate_acme_renewal_discount,
    root_agent,
)

# Test Tool 1: Project lookup
res1 = lookup_double_click_project_status("Double-click")
assert res1["found"] is True and res1["project"]["status"] == "ACTIVE"
res2 = lookup_double_click_project_status("Phoenix")
assert res2["found"] is True and res2["project"]["status"] == "ON_HOLD"

# Test Tool 2: Acme Corp renewal discount calculation
disc = calculate_acme_renewal_discount(420000.0, 25.0)
assert disc["eligible_for_enterprise_discount"] is True
assert disc["final_renewal_acv_usd"] == 357000.0

# Test A2A JSON Agent Card schema
with open(sys.argv[2]) as f:
    card = json.load(f)
assert card["name"] == "double_click_remote_a2a_agent"
assert "displayName" not in card, "AgentCard schema does not accept displayName"
assert "protocolVersion" in card, "AgentCard schema requires protocolVersion"
assert len(card["skills"]) >= 1
print("   ✅ ADK Agent tools and A2A JSON Agent Card passed unit tests.")
' "${ROOT_DIR}" "${ROOT_DIR}/agents/a2a_agent_card/double_click_a2a_agent_card.json"

# 4. Verify Part 3 Widget & UI Terraform module exists
echo "4️⃣  Checking Part 3 Widget & UI Terraform module (terraform/widget_ui.tf)..."
grep -q "google_discovery_engine_widget_config" "${ROOT_DIR}/terraform/widget_ui.tf"
grep -q "SEARCH_WITH_FOLLOW_UPS" "${ROOT_DIR}/terraform/widget_ui.tf"
grep -q "features =" "${ROOT_DIR}/terraform/discovery_engine.tf"
echo "   ✅ Part 3 Widget Config and Feature Management blocks verified."

# 5. Verify Part 4 Observability module & Golden Evaluation Suite
echo "5️⃣  Checking Part 4 Observability module (terraform/observability.tf) & running Golden Evaluation..."
grep -q "google_bigquery_dataset" "${ROOT_DIR}/terraform/observability.tf"
grep -q "google_logging_project_sink" "${ROOT_DIR}/terraform/observability.tf"
grep -q "google_monitoring_dashboard" "${ROOT_DIR}/terraform/observability.tf"
python3 "${ROOT_DIR}/agents/evaluate_agent.py"
echo "   ✅ Part 4 Observability module and Golden Evaluation passed."

# 6. Verify Part 5 Security Terraform module & Intranet Web Portal
echo "6️⃣  Checking Part 5 Security module (terraform/security.tf) & Intranet Web Portal (webapp/)..."
grep -q "google_secret_manager_secret" "${ROOT_DIR}/terraform/security.tf"
grep -q "google_secret_manager_secret_iam_member" "${ROOT_DIR}/terraform/security.tf"
[[ -s "${ROOT_DIR}/webapp/index.html" ]] || { echo "❌ Missing webapp/index.html"; exit 1; }
[[ -s "${ROOT_DIR}/webapp/styles.css" ]] || { echo "❌ Missing webapp/styles.css"; exit 1; }
[[ -s "${ROOT_DIR}/webapp/app.js" ]] || { echo "❌ Missing webapp/app.js"; exit 1; }
grep -q "gen-search-widget" "${ROOT_DIR}/webapp/index.html"
echo "   ✅ Part 5 Secret Manager vault and Intranet Web Portal verified."

# 7. Validate Bash setup script syntax
echo "7️⃣  Checking Bash syntax on scripts/setup_infra.sh..."
bash -n "${ROOT_DIR}/scripts/setup_infra.sh"
echo "   ✅ scripts/setup_infra.sh syntax is clean."

# 8. Validate modular Terraform configuration (init & validate)
echo "8️⃣  Initializing and validating modular Terraform files..."
cd "${ROOT_DIR}/terraform"
terraform init -backend=false > /dev/null
terraform validate
echo "   ✅ Terraform configuration (including security.tf) is valid."

echo "============================================================================"
echo "🎉 ALL PART 1 + PART 2 + PART 3 + PART 4 + PART 5 TESTS PASSED!"
echo "============================================================================"
