#!/usr/bin/env bash
# ============================================================================
# Gemini Enterprise Series — Automated Infrastructure Setup Script
# Branch: 01-knowledge-base-management (Part 1)
#
# Reads configuration from the single root `.env` file, exports `TF_VAR_*`
# variables for Terraform, provisions the Cloud infrastructure, and seeds the
# DoubleClick Enterprise messy data sources (GCS + BigQuery + Discovery Engine).
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
echo "🚀 Setting up Gemini Enterprise Infrastructure (Part 1: Knowledge Base)"
echo "   Project ID:   ${PROJECT_ID}"
echo "   Region:       ${REGION}"
echo "   DE Location:  ${DISCOVERY_ENGINE_LOCATION}"
echo "   App Name:     ${APP_NAME} (${COMPANY_NAME})"
echo "============================================================================"

# 2. Export Terraform variables mapped from .env
export TF_VAR_project_id="${PROJECT_ID}"
export TF_VAR_region="${REGION}"
export TF_VAR_discovery_engine_location="${DISCOVERY_ENGINE_LOCATION}"
export TF_VAR_app_name="${APP_NAME}"
export TF_VAR_company_name="${COMPANY_NAME}"
export TF_VAR_bq_dataset_id="${BQ_DATASET_ID}"
export TF_VAR_gcs_bucket_suffix="${GCS_BUCKET_SUFFIX}"
export TF_VAR_enable_federated_connector="${ENABLE_FEDERATED_CONNECTOR}"
export TF_VAR_federated_connector_source="${FEDERATED_CONNECTOR_SOURCE}"

# 3. Run Terraform Init & Plan/Apply
cd "${ROOT_DIR}/terraform"
terraform init

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "🔍 Running Terraform validation & plan (dry-run mode)..."
  terraform validate
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

# 5. Trigger initial Discovery Engine Document Import from GCS & BigQuery
echo "📚 Triggering Discovery Engine Data Store imports via REST API..."
ACCESS_TOKEN="$(gcloud auth print-access-token)"
API_HOST="discoveryengine.googleapis.com"
if [[ "${DISCOVERY_ENGINE_LOCATION}" != "global" ]]; then
  API_HOST="${DISCOVERY_ENGINE_LOCATION}-discoveryengine.googleapis.com"
fi

# Import unstructured documents from GCS into the Unstructured Data Store
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

# Import structured rows from BigQuery into the Structured Data Store
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

echo "✅ Part 1 Knowledge Base setup and ingestion triggered successfully!"
