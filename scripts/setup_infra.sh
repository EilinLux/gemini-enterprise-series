#!/usr/bin/env bash
# ============================================================================
# Gemini Enterprise Series — Automated Infrastructure Setup Script
# Branch: 05-integration-and-security (Complete 5-Part Enterprise Stack)
#
# Reads configuration from the single root `.env` file, exports `TF_VAR_*`
# variables for Terraform, provisions:
#   - Part 1: Knowledge Base (GCS Unstructured + BigQuery Structured + Connectors)
#   - Part 2: Conversational Modeling (Dialogflow CX + Playbook + ADK + A2A)
#   - Part 3: UX/UI & Accessibility (Branding Logo, Widget Config & Governance)
#   - Part 4: Architecture & Monitoring (BigQuery Log Dataset, Eval Table & Dashboard)
#   - Part 5: Integration & Security (Secret Manager OAuth Vault, IAM & Intranet Portal)
# ============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "⚠️  No .env file found at ${ENV_FILE}. Copying from .env.example..."
  cp "${ROOT_DIR}/.env.example" "${ENV_FILE}"
fi

# 1. Load variables from .env
set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

echo "============================================================================"
echo "🚀 Setting up Complete Gemini Enterprise Stack (Parts 1–5: Security & Portal)"
echo "   Project ID:         ${PROJECT_ID}"
echo "   Region:             ${REGION}"
echo "   DE Location:        ${DISCOVERY_ENGINE_LOCATION}"
echo "   App Name:           ${APP_NAME} (${COMPANY_NAME})"
echo "   OAuth Secret Vault: ${OAUTH_ACTION_SECRET_ID}"
echo "   Portal Port:        ${PORTAL_PORT}"
echo "============================================================================"

# 2. Export Terraform variables mapped from .env (Parts 1–5)
export TF_VAR_project_id="${PROJECT_ID}"
export TF_VAR_region="${REGION}"
export TF_VAR_discovery_engine_location="${DISCOVERY_ENGINE_LOCATION}"
export TF_VAR_app_name="${APP_NAME}"
export TF_VAR_company_name="${COMPANY_NAME}"
export TF_VAR_bq_dataset_id="${BQ_DATASET_ID}"
export TF_VAR_gcs_bucket_suffix="${GCS_BUCKET_SUFFIX}"
export TF_VAR_enable_federated_connector="${ENABLE_FEDERATED_CONNECTOR}"
export TF_VAR_federated_connector_source="${FEDERATED_CONNECTOR_SOURCE}"
export TF_VAR_dialogflow_time_zone="${DIALOGFLOW_TIME_ZONE}"
export TF_VAR_dialogflow_default_language="${DIALOGFLOW_DEFAULT_LANGUAGE}"
export TF_VAR_adk_agent_display_name="${ADK_AGENT_DISPLAY_NAME}"
export TF_VAR_gemini_model="${GEMINI_MODEL}"
export TF_VAR_company_logo_url="${COMPANY_LOGO_URL}"
export TF_VAR_shortcut_title="${SHORTCUT_TITLE}"
export TF_VAR_shortcut_url="${SHORTCUT_URL}"
export TF_VAR_allowlisted_domains="${ALLOWLISTED_DOMAINS}"
export TF_VAR_bq_log_sink_dataset_id="${BQ_LOGS_DATASET_ID}"
export TF_VAR_enable_cloud_trace="${GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY}"
export TF_VAR_oauth_action_secret_id="${OAUTH_ACTION_SECRET_ID}"
export TF_VAR_enable_workforce_identity="${ENABLE_WORKFORCE_IDENTITY}"
export TF_VAR_workforce_pool_id="${WORKFORCE_POOL_ID}"
export TF_VAR_portal_port="${PORTAL_PORT}"

# 3. Run Terraform Init & Plan/Apply
cd "${ROOT_DIR}/terraform"
terraform init

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "🔍 Running Terraform validation, ADK dry-run & Part 4/5 verification..."
  terraform validate
  python3 "${ROOT_DIR}/agents/adk_double_click_agent/deploy_agent_engine.py" --dry-run
  python3 "${ROOT_DIR}/agents/evaluate_agent.py"
  exit 0
fi

terraform apply -auto-approve

# 4. Inject the live Widget Config ID into webapp/index.html if available
LIVE_CONFIG_ID="$(terraform output -raw widget_obfuscated_config_id 2>/dev/null || true)"
if [[ -n "${LIVE_CONFIG_ID}" ]]; then
  echo "🎨 Syncing live Widget configId (${LIVE_CONFIG_ID}) into webapp/index.html..."
  python3 -c '
import re, sys
path, cid = sys.argv[1], sys.argv[2]
with open(path, "r", encoding="utf-8") as f:
    html = f.read()
html = re.sub(r"configId=\"[^\"]+\"", f"configId=\"{cid}\"", html)
html = re.sub(r"id=\"widgetConfigIdInput\"\s+class=\"mono-input\"\s+value=\"[^\"]+\"", f"id=\"widgetConfigIdInput\"\n          class=\"mono-input\"\n          value=\"{cid}\"", html)
with open(path, "w", encoding="utf-8") as f:
    f.write(html)
' "${ROOT_DIR}/webapp/index.html" "${LIVE_CONFIG_ID}"
fi

# 5. Populate BigQuery Structured Tables with DoubleClick Enterprise JSONL data
echo "📊 Seeding BigQuery tables (${BQ_DATASET_ID}.project_db & retail_sales)..."
bq --project_id="${PROJECT_ID}" load \
  --source_format=NEWLINE_DELIMITED_JSON \
  --replace \
  "${BQ_DATASET_ID}.project_db" \
  "${ROOT_DIR}/data/structured/project_db.jsonl"

bq --project_id="${PROJECT_ID}" load \
  --source_format=NEWLINE_DELIMITED_JSON \
  --replace \
  "${BQ_DATASET_ID}.retail_sales" \
  "${ROOT_DIR}/data/structured/retail_sales.jsonl"

# 6. Trigger Discovery Engine Document Import from GCS & BigQuery
echo "📚 Triggering Discovery Engine Data Store imports via REST API..."
ACCESS_TOKEN="$(gcloud auth print-access-token)"
API_HOST="discoveryengine.googleapis.com"
if [[ "${DISCOVERY_ENGINE_LOCATION}" != "global" ]]; then
  API_HOST="${DISCOVERY_ENGINE_LOCATION}-discoveryengine.googleapis.com"
fi

curl -s -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://${API_HOST}/v1/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/collections/default_collection/dataStores/${APP_NAME}-unstructured-ds/branches/0/documents:import" \
  -d "{
    \"gcsSource\": {
      \"inputUris\": [\"gs://${PROJECT_ID}-${APP_NAME}-${GCS_BUCKET_SUFFIX}/unstructured/*\"],
      \"dataSchema\": \"content\"
    },
    \"reconciliationMode\": \"INCREMENTAL\"
  }" > /dev/null

curl -s -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://${API_HOST}/v1/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/collections/default_collection/dataStores/${APP_NAME}-structured-bq-ds/branches/0/documents:import" \
  -d "{
    \"bigquerySource\": {
      \"projectId\": \"${PROJECT_ID}\",
      \"datasetId\": \"${BQ_DATASET_ID}\",
      \"tableId\": \"project_db\",
      \"dataSchema\": \"custom\"
    },
    \"reconciliationMode\": \"FULL\"
  }" > /dev/null

# 7. Configure Gemini Enterprise App Default Assistant (System Instructions & Banned Phrases)
echo "🤖 Configuring Default Assistant inside ${APP_NAME}-enterprise-app..."
curl -s -X PATCH \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://${API_HOST}/v1alpha/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/collections/default_collection/engines/${APP_NAME}-enterprise-app/assistants/default_assistant?updateMask=generationConfig,customerPolicy,webGroundingType" \
  -d "{
    \"webGroundingType\": \"WEB_GROUNDING_TYPE_GOOGLE_SEARCH\",
    \"generationConfig\": {
      \"defaultLanguage\": \"${DIALOGFLOW_DEFAULT_LANGUAGE}\",
      \"systemInstruction\": {
        \"additionalSystemInstruction\": \"You are the official ${COMPANY_NAME} AI Assistant. Always ground your answers in the connected ${COMPANY_NAME} Data Stores (WFH Policy V2, Acme Corp MSA 2026, IT Security Playbook, and BigQuery project_db / retail_sales tables) and cite the exact source.\"
      }
    },
    \"customerPolicy\": {
      \"bannedPhrases\": [
        {
          \"phrase\": \"Project Chimera\",
          \"matchType\": \"SIMPLE_STRING_MATCH\",
          \"ignoreDiacritics\": true
        }
      ]
    }
  }" > /dev/null

# 8. Run Part 4 Continuous Quality & Trajectory Evaluation Suite & Export to BigQuery
echo "🧪 Running Part 4 Golden Dataset Evaluation Suite & exporting to BigQuery (${BQ_LOGS_DATASET_ID}.agent_telemetry_and_eval_logs)..."
EVAL_TMP_JSONL="${ROOT_DIR}/terraform/.eval_results.jsonl"
python3 "${ROOT_DIR}/agents/evaluate_agent.py" --output-jsonl "${EVAL_TMP_JSONL}"
bq --project_id="${PROJECT_ID}" load \
  --source_format=NEWLINE_DELIMITED_JSON \
  --replace \
  "${BQ_LOGS_DATASET_ID}.agent_telemetry_and_eval_logs" \
  "${EVAL_TMP_JSONL}"
rm -f "${EVAL_TMP_JSONL}"

echo "✅ Complete 5-Part Gemini Enterprise Stack Deployed!"
echo "👉 Launch the DoubleClick Enterprise Intranet Web Portal on http://localhost:${PORTAL_PORT}:"
echo "   python3 webapp/serve_portal.py --port ${PORTAL_PORT}"
