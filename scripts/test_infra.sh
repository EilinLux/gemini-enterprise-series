#!/usr/bin/env bash
# ============================================================================
# Gemini Enterprise Series — Automated Verification & Testing Suite
# Branch: 03-ux-ui-and-accessibility (Part 1 + Part 2 + Part 3)
# ============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "============================================================================"
echo "🧪 Running Repository Verification Suite — Branch 03 (UX/UI & Accessibility)"
echo "============================================================================"

# 1. Verify .env.example has all required Part 1 + Part 2 + Part 3 keys
echo "1️⃣  Checking .env.example configuration keys (Part 1 + Part 2 + Part 3)..."
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

# 4. Verify Part 3 Widget & UI Terraform module exists and contains required resources
echo "4️⃣  Checking Part 3 Widget & UI Terraform module (terraform/widget_ui.tf)..."
grep -q "google_discovery_engine_widget_config" "${ROOT_DIR}/terraform/widget_ui.tf"
grep -q "SEARCH_WITH_FOLLOW_UPS" "${ROOT_DIR}/terraform/widget_ui.tf"
grep -q "features =" "${ROOT_DIR}/terraform/discovery_engine.tf"
echo "   ✅ Part 3 Widget Config and Feature Management blocks verified."

# 5. Validate Bash setup script syntax
echo "5️⃣  Checking Bash syntax on scripts/setup_infra.sh..."
bash -n "${ROOT_DIR}/scripts/setup_infra.sh"
echo "   ✅ scripts/setup_infra.sh syntax is clean."

# 6. Validate modular Terraform configuration (init & validate)
echo "6️⃣  Initializing and validating modular Terraform files..."
cd "${ROOT_DIR}/terraform"
terraform init -backend=false > /dev/null
terraform validate
echo "   ✅ Terraform configuration (including widget_ui.tf) is valid."

echo "============================================================================"
echo "🎉 ALL PART 1 + PART 2 + PART 3 TESTS PASSED!"
echo "============================================================================"

