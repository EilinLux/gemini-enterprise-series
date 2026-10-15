#!/usr/bin/env bash
# ============================================================================
# Gemini Enterprise Series — Automated Verification & Testing Suite
# Branch: 01-knowledge-base-management (Part 1)
# ============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "============================================================================"
echo "🧪 Running Repository Verification Suite — Branch 01 (Knowledge Base)"
echo "============================================================================"

# 1. Verify .env.example has all required keys
echo "1️⃣  Checking .env.example configuration keys..."
REQUIRED_KEYS=(
  "PROJECT_ID"
  "REGION"
  "DISCOVERY_ENGINE_LOCATION"
  "APP_NAME"
  "COMPANY_NAME"
  "BQ_DATASET_ID"
  "GCS_BUCKET_SUFFIX"
  "FEDERATED_CONNECTOR_SOURCE"
  "ENABLE_FEDERATED_CONNECTOR"
)

for key in "${REQUIRED_KEYS[@]}"; do
  if ! grep -q "^${key}=" "${ROOT_DIR}/.env.example"; then
    echo "❌ Missing required key in .env.example: ${key}"
    exit 1
  fi
done
echo "   ✅ All required .env keys present."

# 2. Verify DoubleClick Enterprise messy data files exist and are valid
echo "2️⃣  Validating DoubleClick Enterprise sample data files (Unstructured & Structured)..."
for doc in WFH_Policy_Update_V2.txt Acme_Corp_Master_Services_Agreement_2026.txt IT_Security_Onboarding_Playbook.txt; do
  if [[ ! -s "${ROOT_DIR}/data/unstructured/${doc}" ]]; then
    echo "❌ Missing or empty unstructured document: ${doc}"
    exit 1
  fi
done

python3 -c '
import json, sys
for path in sys.argv[1:]:
    with open(path) as f:
        lines = [json.loads(line) for line in f if line.strip()]
    assert len(lines) >= 3, f"Expected at least 3 records in {path}"
print("   ✅ Structured JSONL files (project_db.jsonl & retail_sales.jsonl) are valid JSON Lines.")
' "${ROOT_DIR}/data/structured/project_db.jsonl" "${ROOT_DIR}/data/structured/retail_sales.jsonl"

# 3. Validate Bash setup script syntax
echo "3️⃣  Checking Bash syntax on scripts/setup_infra.sh..."
bash -n "${ROOT_DIR}/scripts/setup_infra.sh"
echo "   ✅ scripts/setup_infra.sh syntax is clean."

# 4. Validate Terraform configuration (init & validate)
echo "4️⃣  Initializing and validating Terraform configuration..."
cd "${ROOT_DIR}/terraform"
terraform init -backend=false > /dev/null
terraform validate
echo "   ✅ Terraform configuration is syntactically and semantically valid."

echo "============================================================================"
echo "🎉 ALL PART 1 TESTS PASSED!"
echo "============================================================================"
