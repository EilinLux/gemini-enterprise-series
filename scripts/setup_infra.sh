#!/usr/bin/env bash
# ============================================================================
# Gemini Enterprise Series — Automated Infrastructure Setup Script
# Branch: 03-ux-ui-and-accessibility (Part 1 + Part 2 + Part 3)
#
# Reads configuration from the single root `.env` file, exports `TF_VAR_*`
# variables for Terraform, provisions Part 1 (Knowledge Base) + Part 2
# (Agents) + Part 3 (UX/UI, Branding Logo, Widget Config & Feature Management),
# and seeds the data stores.
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
echo "🚀 Setting up Gemini Enterprise Infrastructure (Part 1 + Part 2 + Part 3: UX/UI)"
echo "   Project ID:   ${PROJECT_ID}"
echo "   Region:       ${REGION}"
echo "   DE Location:  ${DISCOVERY_ENGINE_LOCATION}"
echo "   App Name:     ${APP_NAME} (${COMPANY_NAME})"
echo "   Brand Logo:   ${COMPANY_LOGO_URL}"
echo "============================================================================"

# 2. Export Terraform variables mapped from .env (Part 1 + Part 2 + Part 3)
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


export TF_VAR_enable_ces_studio_app="${ENABLE_CES_STUDIO_APP:-false}"
export TF_VAR_grant_project_iam_roles="${GRANT_PROJECT_IAM_ROLES:-false}"

# 3. Enable Required Google Cloud APIs via gcloud
echo "🔌 Ensuring required Google Cloud APIs are enabled for ${PROJECT_ID}..."
REQUIRED_APIS=(
  "discoveryengine.googleapis.com"
  "bigquery.googleapis.com"
  "storage.googleapis.com"
  "dialogflow.googleapis.com"
  "aiplatform.googleapis.com"
  "iam.googleapis.com"
)
if [[ "${TF_VAR_enable_ces_studio_app}" == "true" ]]; then
  REQUIRED_APIS+=("ces.googleapis.com")
fi

gcloud services enable "${REQUIRED_APIS[@]}" --project="${PROJECT_ID}"

# 4. Run Terraform Init & Plan/Apply
cd "${ROOT_DIR}/terraform"
terraform init

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "🔍 Running Terraform validation & ADK dry-run check..."
  terraform validate
  python3 "${ROOT_DIR}/agents/adk_double_click_agent/deploy_agent_engine.py" --dry-run
  exit 0
fi

if [[ "${1:-}" == "--plan" ]]; then
  echo "📋 Running Terraform Plan using variables sourced from .env..."
  terraform plan
  exit 0
fi

terraform apply -auto-approve

# 5. Populate BigQuery Structured Tables with DoubleClick Enterprise JSONL data
echo "📊 Seeding BigQuery tables (${BQ_DATASET_ID}.project_db & retail_sales)..."
bq --project_id="${PROJECT_ID}" --location="${REGION}" load \
  --source_format=NEWLINE_DELIMITED_JSON \
  --replace \
  "${BQ_DATASET_ID}.project_db" \
  "${ROOT_DIR}/data/structured/project_db.jsonl"

bq --project_id="${PROJECT_ID}" --location="${REGION}" load \
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

UNSTRUCTURED_RESP=$(curl -s -w "\n%{http_code}" -X POST \
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
  }")
UNSTRUCTURED_HTTP_CODE=$(echo "${UNSTRUCTURED_RESP}" | tail -n1)
echo "   Unstructured docs import triggered (HTTP ${UNSTRUCTURED_HTTP_CODE})."

STRUCTURED_RESP=$(curl -s -w "\n%{http_code}" -X POST \
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
  }")
STRUCTURED_HTTP_CODE=$(echo "${STRUCTURED_RESP}" | tail -n1)
echo "   Structured BigQuery import triggered (HTTP ${STRUCTURED_HTTP_CODE})."

# 7. Configure Gemini Enterprise App Default Assistant (System Instructions & Banned Phrases)
echo "🤖 Configuring Default Assistant inside ${APP_NAME}-enterprise-app..."
ASSISTANT_RESP=$(curl -s -w "\n%{http_code}" -X PATCH \
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
  }")
ASSISTANT_HTTP_CODE=$(echo "${ASSISTANT_RESP}" | tail -n1)
echo "   Default Assistant configured (HTTP ${ASSISTANT_HTTP_CODE})."

echo "✅ Part 1, Part 2 & Part 3 (UX/UI, Widget & Branding) infrastructure deployed!"
echo "👉 Run 'terraform -chdir=terraform output dialogflow_cx_agent_resource_name' to copy your Dialogflow Agent path."
echo "👉 Run 'python3 agents/adk_double_click_agent/deploy_agent_engine.py' to deploy the ADK Agent to Vertex AI Agent Engine."

