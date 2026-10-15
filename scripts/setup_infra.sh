#!/usr/bin/env bash
# ============================================================================
# Gemini Enterprise Series — Automated Infrastructure Setup Script
# Branch: 04-architecture-and-monitoring (Part 1 + Part 2 + Part 3 + Part 4)
#
# Reads configuration from the single root `.env` file, exports `TF_VAR_*`
# variables for Terraform, provisions Part 1 (Knowledge Base) + Part 2
# (Agents) + Part 3 (UX/UI & Widget Config) + Part 4 (Observability: BigQuery
# Log Sink, Cloud Monitoring Dashboard & Trace), seeds the data stores, and
# runs the Part 4 Golden Evaluation Suite.
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
echo "🚀 Setting up Gemini Enterprise Infrastructure (Parts 1–4: Observability)"
echo "   Project ID:        ${PROJECT_ID}"
echo "   Region:            ${REGION}"
echo "   DE Location:       ${DISCOVERY_ENGINE_LOCATION}"
echo "   App Name:          ${APP_NAME} (${COMPANY_NAME})"
echo "   Log Sink Dataset:  ${BQ_LOGS_DATASET_ID}"
echo "   Cloud Trace:       ${GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY}"
echo "============================================================================"

# 2. Export Terraform variables mapped from .env (Part 1 + Part 2 + Part 3 + Part 4)
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

# 3. Run Terraform Init & Plan/Apply
cd "${ROOT_DIR}/terraform"
terraform init

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "🔍 Running Terraform validation, ADK dry-run & Part 4 Golden Evaluation..."
  terraform validate
  python3 "${ROOT_DIR}/agents/adk_double_click_agent/deploy_agent_engine.py" --dry-run
  python3 "${ROOT_DIR}/agents/evaluate_agent.py"
  exit 0
fi

terraform apply -auto-approve

# 4. Populate BigQuery Structured Tables with DoubleClick Enterprise JSONL data
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

# 5. Trigger Discovery Engine Document Import from GCS & BigQuery
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

# 6. Configure Gemini Enterprise App Default Assistant (System Instructions & Banned Phrases)
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

# 7. Run Part 4 Continuous Quality & Trajectory Evaluation Suite & Export to BigQuery
echo "🧪 Running Part 4 Golden Dataset Evaluation Suite & exporting to BigQuery (${BQ_LOGS_DATASET_ID}.agent_telemetry_and_eval_logs)..."
EVAL_TMP_JSONL="${ROOT_DIR}/terraform/.eval_results.jsonl"
python3 "${ROOT_DIR}/agents/evaluate_agent.py" --output-jsonl "${EVAL_TMP_JSONL}"
bq --project_id="${PROJECT_ID}" load \
  --source_format=NEWLINE_DELIMITED_JSON \
  --replace \
  "${BQ_LOGS_DATASET_ID}.agent_telemetry_and_eval_logs" \
  "${EVAL_TMP_JSONL}"
rm -f "${EVAL_TMP_JSONL}"

echo "✅ Parts 1–4 infrastructure, BigQuery Observability Dataset (${BQ_LOGS_DATASET_ID}), and Cloud Monitoring Dashboard deployed!"
echo "👉 Run 'terraform -chdir=terraform output cloud_monitoring_dashboard_id' to inspect your Monitoring Dashboard."
