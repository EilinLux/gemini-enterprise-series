#!/usr/bin/env bash
# ============================================================================
# Gemini Enterprise Series — Live Cloud Infrastructure Verification Script
# Branch: 03-ux-ui-and-accessibility (Part 1 + Part 2 + Part 3)
#
# Connects to live Google Cloud APIs using ADC credentials to verify all
# resources provisioned across Part 1, Part 2, and Part 3:
#  1. Cloud Storage bucket and ingested documents
#  2. BigQuery dataset and table row counts
#  3. Discovery Engine Data Stores and Intranet App
#  4. Dialogflow CX Agent and Generative Task Playbook
#  5. Gemini Enterprise Assistant connected agents
#  6. Vertex AI Agent Engine Service Account & IAM
#  7. (Part 3) Discovery Engine Widget Config, Branding Logo & Features
# ============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "❌ Error: .env file not found at ${ENV_FILE}"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

echo "============================================================================"
echo "🔍 Verifying Live Cloud Infrastructure on GCP (Branch 03: UX/UI)"
echo "   Project:     ${PROJECT_ID}"
echo "   Region:      ${REGION}"
echo "   DE Location: ${DISCOVERY_ENGINE_LOCATION}"
echo "   App Name:    ${APP_NAME} (${COMPANY_NAME})"
echo "   Brand Logo:  ${COMPANY_LOGO_URL}"
echo "============================================================================"

ACCESS_TOKEN="$(gcloud auth print-access-token)"
API_HOST="discoveryengine.googleapis.com"
if [[ "${DISCOVERY_ENGINE_LOCATION}" != "global" ]]; then
  API_HOST="${DISCOVERY_ENGINE_LOCATION}-discoveryengine.googleapis.com"
fi

# 1. Cloud Storage Verification
echo ""
echo "1️⃣  Verifying Google Cloud Storage Bucket & Documents..."
BUCKET_NAME="${PROJECT_ID}-${APP_NAME}-${GCS_BUCKET_SUFFIX}"
GCS_RESP=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "https://storage.googleapis.com/storage/v1/b/${BUCKET_NAME}")

if [[ "${GCS_RESP}" == "200" ]]; then
  echo "   ✅ Bucket exists: gs://${BUCKET_NAME}"
  OBJECTS_RESP=$(curl -s \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    "https://storage.googleapis.com/storage/v1/b/${BUCKET_NAME}/o?prefix=unstructured/")
  DOC_COUNT=$(echo "${OBJECTS_RESP}" | grep -c '"name":' || true)
  echo "   ✅ Found ${DOC_COUNT} objects under gs://${BUCKET_NAME}/unstructured/"
else
  echo "   ❌ Bucket gs://${BUCKET_NAME} not found (HTTP ${GCS_RESP})."
fi

# 2. BigQuery Verification
echo ""
echo "2️⃣  Verifying BigQuery Dataset & Tables..."
BQ_RESP=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "https://bigquery.googleapis.com/bigquery/v2/projects/${PROJECT_ID}/datasets/${BQ_DATASET_ID}")

if [[ "${BQ_RESP}" == "200" ]]; then
  echo "   ✅ Dataset exists: ${PROJECT_ID}:${BQ_DATASET_ID}"
  for TABLE in "project_db" "retail_sales"; do
    ROWS_RESP=$(curl -s \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      "https://bigquery.googleapis.com/bigquery/v2/projects/${PROJECT_ID}/datasets/${BQ_DATASET_ID}/tables/${TABLE}")
    NUM_ROWS=$(echo "${ROWS_RESP}" | grep '"numRows":' | tr -dc '0-9' || echo "0")
    echo "   ✅ Table ${TABLE} verified (${NUM_ROWS:-0} rows)."
  done
else
  echo "   ❌ Dataset ${BQ_DATASET_ID} not found (HTTP ${BQ_RESP})."
fi

# 3. Discovery Engine Data Stores & App
echo ""
echo "3️⃣  Verifying Discovery Engine Data Stores & Enterprise App..."
for DS in "${APP_NAME}-unstructured-ds" "${APP_NAME}-structured-bq-ds"; do
  DS_RESP=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "X-Goog-User-Project: ${PROJECT_ID}" \
    "https://${API_HOST}/v1/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/collections/default_collection/dataStores/${DS}")
  if [[ "${DS_RESP}" == "200" ]]; then
    echo "   ✅ Data Store exists: ${DS}"
  else
    echo "   ❌ Data Store ${DS} not found (HTTP ${DS_RESP})."
  fi
done

APP_RESP=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://${API_HOST}/v1/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/collections/default_collection/engines/${APP_NAME}-enterprise-app")

if [[ "${APP_RESP}" == "200" ]]; then
  echo "   ✅ Gemini Enterprise App exists: ${APP_NAME}-enterprise-app"
else
  echo "   ❌ Gemini Enterprise App not found (HTTP ${APP_RESP})."
fi

# 4. Dialogflow CX Agent & Playbook
echo ""
echo "4️⃣  Verifying Dialogflow CX Agent & Generative Playbook..."
DF_AGENTS_RESP=$(curl -s \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://dialogflow.googleapis.com/v3/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/agents")

AGENT_NAME=$(echo "${DF_AGENTS_RESP}" | grep -B 1 "\"displayName\": \"${APP_NAME}_cx_custom_qa_agent\"" | head -n 1 | tr -d ' ",' | cut -d: -f2- || true)

if [[ -n "${AGENT_NAME}" ]]; then
  echo "   ✅ Dialogflow CX Agent exists: ${AGENT_NAME}"
  PLAYBOOKS_RESP=$(curl -s \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "X-Goog-User-Project: ${PROJECT_ID}" \
    "https://dialogflow.googleapis.com/v3/${AGENT_NAME}/playbooks")
  PLAYBOOK_COUNT=$(echo "${PLAYBOOKS_RESP}" | grep -c '"displayName":' || true)
  echo "   ✅ Found ${PLAYBOOK_COUNT} Generative Playbook(s) inside agent."
else
  echo "   ⚠️  Dialogflow CX Agent '${APP_NAME}_cx_custom_qa_agent' not found in location ${DISCOVERY_ENGINE_LOCATION}."
fi

# 5. Gemini Enterprise Assistant Configuration
echo ""
echo "5️⃣  Verifying Gemini Enterprise Assistant & Connected Agents..."
ASSISTANT_GET=$(curl -s \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://${API_HOST}/v1alpha/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/collections/default_collection/engines/${APP_NAME}-enterprise-app/assistants/default_assistant")

if echo "${ASSISTANT_GET}" | grep -q "bannedPhrases"; then
  echo "   ✅ Assistant Customer Policy verified (banned phrases configured)."
else
  echo "   ℹ️  Assistant policy returned: $(echo "${ASSISTANT_GET}" | head -n 2)"
fi

# 6. Vertex AI Agent Engine Service Account
echo ""
echo "6️⃣  Verifying Vertex AI Agent Engine Service Account..."
SA_EMAIL="${APP_NAME}-adk-agent-sa@${PROJECT_ID}.iam.gserviceaccount.com"
SA_RESP=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "https://iam.googleapis.com/v1/projects/${PROJECT_ID}/serviceAccounts/${SA_EMAIL}")

if [[ "${SA_RESP}" == "200" ]]; then
  echo "   ✅ ADK Service Account exists: ${SA_EMAIL}"
else
  echo "   ❌ ADK Service Account not found (HTTP ${SA_RESP})."
fi

# 7. (Part 3) Discovery Engine Widget Config, Branding Logo & Access Settings
echo ""
echo "7️⃣  Verifying Part 3 Widget Config, Branding Logo & Access Settings..."
WIDGET_CONFIG_RESP=$(curl -s \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://${API_HOST}/v1alpha/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/collections/default_collection/engines/${APP_NAME}-enterprise-app/widgetConfigs/default_search_widget_config")

if echo "${WIDGET_CONFIG_RESP}" | grep -q "uiBranding"; then
  echo "   ✅ Widget Config exists: default_search_widget_config"
  if echo "${WIDGET_CONFIG_RESP}" | grep -q "${COMPANY_LOGO_URL}"; then
    echo "   ✅ Brand Logo configured: ${COMPANY_LOGO_URL}"
  else
    echo "   ℹ️  Logo URL in config: $(echo "${WIDGET_CONFIG_RESP}" | grep -A 2 'logo' || true)"
  fi
  if echo "${WIDGET_CONFIG_RESP}" | grep -q "SEARCH_WITH_FOLLOW_UPS"; then
    echo "   ✅ Interaction type set to: SEARCH_WITH_FOLLOW_UPS"
  fi
  if echo "${WIDGET_CONFIG_RESP}" | grep -q "allowlistedDomains"; then
    echo "   ✅ Allowlisted domains configured in Access Settings."
  fi
else
  echo "   ℹ️  Widget Config response: ${WIDGET_CONFIG_RESP}"
fi

echo ""
echo "============================================================================"
echo "🎉 ALL LIVE CLOUD INFRASTRUCTURE VERIFICATION CHECKS COMPLETED!"
echo "============================================================================"
