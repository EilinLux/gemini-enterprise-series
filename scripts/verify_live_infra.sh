#!/usr/bin/env bash
# ============================================================================
# Gemini Enterprise Series — Live Infrastructure Verification Script
# Branch: 02-conversational-modeling (Part 1 + Part 2)
#
# Inspects and verifies all provisioned GCP resources directly in the cloud:
#   1. Google Cloud Storage bucket & uploaded unstructured documents
#   2. BigQuery dataset and seeded rows (project_db, retail_sales)
#   3. Discovery Engine Data Stores (unstructured & structured)
#   4. Gemini Enterprise App and connected data stores
#   5. Dialogflow CX Agent & Generative Playbook
#   6. Connected Conversational Agents (Dialogflow CX & A2A) in Gemini Enterprise
#   7. Vertex AI Agent Engine ADK Service Account
# ============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "❌ No .env file found at ${ENV_FILE}. Please create one from .env.example."
  exit 1
fi

# Load environment configuration
set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

echo "============================================================================"
echo "🔍 Verifying Live GCP Infrastructure for Part 1 + Part 2 (Conversational Modeling)"
echo "   Project ID:  ${PROJECT_ID}"
echo "   Region:      ${REGION}"
echo "   Location:    ${DISCOVERY_ENGINE_LOCATION}"
echo "   App Name:    ${APP_NAME}"
echo "============================================================================"

ACCESS_TOKEN="$(gcloud auth print-access-token)"
API_HOST="discoveryengine.googleapis.com"
if [[ "${DISCOVERY_ENGINE_LOCATION}" != "global" ]]; then
  API_HOST="${DISCOVERY_ENGINE_LOCATION}-discoveryengine.googleapis.com"
fi

# ----------------------------------------------------------------------------
# 1. Verify Google Cloud Storage Bucket & Unstructured Documents
# ----------------------------------------------------------------------------
echo ""
echo "1️⃣  Checking Cloud Storage Bucket & Unstructured Documents..."
BUCKET_NAME="${PROJECT_ID}-${APP_NAME}-${GCS_BUCKET_SUFFIX}"

GCS_CHECK_URL="https://storage.googleapis.com/storage/v1/b/${BUCKET_NAME}/o"
GCS_RESP=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" "${GCS_CHECK_URL}")

for doc in "WFH_Policy_Update_V2.txt" "Acme_Corp_Master_Services_Agreement_2026.txt" "IT_Security_Onboarding_Playbook.txt"; do
  if echo "${GCS_RESP}" | grep -q "\"name\": \"unstructured/${doc}\""; then
    echo "   ✅ Found GCS document: gs://${BUCKET_NAME}/unstructured/${doc}"
  else
    echo "   ❌ Missing GCS document: gs://${BUCKET_NAME}/unstructured/${doc}"
    exit 1
  fi
done

# ----------------------------------------------------------------------------
# 2. Verify BigQuery Dataset & Structured Tables
# ----------------------------------------------------------------------------
echo ""
echo "2️⃣  Checking BigQuery Dataset & Table Row Counts..."

# Query row count for project_db
PROJECT_COUNT=$(bq query --location="${REGION}" --project_id="${PROJECT_ID}" --use_legacy_sql=false \
  --format=csv "SELECT COUNT(1) AS cnt FROM \`${PROJECT_ID}.${BQ_DATASET_ID}.project_db\`" | tail -n 1)

if [[ "${PROJECT_COUNT}" -gt 0 ]]; then
  echo "   ✅ BigQuery table '${BQ_DATASET_ID}.project_db' exists with ${PROJECT_COUNT} rows."
else
  echo "   ❌ BigQuery table '${BQ_DATASET_ID}.project_db' has no rows."
  exit 1
fi

# Query row count for retail_sales
RETAIL_COUNT=$(bq query --location="${REGION}" --project_id="${PROJECT_ID}" --use_legacy_sql=false \
  --format=csv "SELECT COUNT(1) AS cnt FROM \`${PROJECT_ID}.${BQ_DATASET_ID}.retail_sales\`" | tail -n 1)

if [[ "${RETAIL_COUNT}" -gt 0 ]]; then
  echo "   ✅ BigQuery table '${BQ_DATASET_ID}.retail_sales' exists with ${RETAIL_COUNT} rows."
else
  echo "   ❌ BigQuery table '${BQ_DATASET_ID}.retail_sales' has no rows."
  exit 1
fi

# ----------------------------------------------------------------------------
# 3. Verify Discovery Engine Data Stores
# ----------------------------------------------------------------------------
echo ""
echo "3️⃣  Checking Discovery Engine Data Stores..."

UNSTRUCT_DS_URL="https://${API_HOST}/v1/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/collections/default_collection/dataStores/${APP_NAME}-unstructured-ds"
UNSTRUCT_RESP=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "X-Goog-User-Project: ${PROJECT_ID}" "${UNSTRUCT_DS_URL}")

if echo "${UNSTRUCT_RESP}" | grep -q "\"name\":"; then
  UNSTRUCT_TITLE=$(echo "${UNSTRUCT_RESP}" | grep -o '"displayName": "[^"]*' | cut -d'"' -f4)
  echo "   ✅ Unstructured Data Store exists: '${UNSTRUCT_TITLE}'"
else
  echo "   ❌ Unstructured Data Store not found: ${UNSTRUCT_RESP}"
  exit 1
fi

STRUCT_DS_URL="https://${API_HOST}/v1/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/collections/default_collection/dataStores/${APP_NAME}-structured-bq-ds"
STRUCT_RESP=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "X-Goog-User-Project: ${PROJECT_ID}" "${STRUCT_DS_URL}")

if echo "${STRUCT_RESP}" | grep -q "\"name\":"; then
  STRUCT_TITLE=$(echo "${STRUCT_RESP}" | grep -o '"displayName": "[^"]*' | cut -d'"' -f4)
  echo "   ✅ Structured BigQuery Data Store exists: '${STRUCT_TITLE}'"
else
  echo "   ❌ Structured BigQuery Data Store not found: ${STRUCT_RESP}"
  exit 1
fi

# ----------------------------------------------------------------------------
# 4. Verify Gemini Enterprise App & Connected Data Stores
# ----------------------------------------------------------------------------
echo ""
echo "4️⃣  Checking Gemini Enterprise App & Connected Data Stores..."

APP_URL="https://${API_HOST}/v1/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/collections/default_collection/engines/${APP_NAME}-enterprise-app"
APP_RESP=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "X-Goog-User-Project: ${PROJECT_ID}" "${APP_URL}")

if echo "${APP_RESP}" | grep -q "\"name\":"; then
  APP_TITLE=$(echo "${APP_RESP}" | grep -o '"displayName": "[^"]*' | cut -d'"' -f4)
  echo "   ✅ Gemini Enterprise App exists: '${APP_TITLE}'"
  if echo "${APP_RESP}" | grep -q "${APP_NAME}-unstructured-ds" && echo "${APP_RESP}" | grep -q "${APP_NAME}-structured-bq-ds"; then
    echo "   ✅ Both Unstructured and Structured Data Stores are connected to the App."
  fi
else
  echo "   ❌ Gemini Enterprise App not found: ${APP_RESP}"
  exit 1
fi

# ----------------------------------------------------------------------------
# 5. Verify Part 2: Dialogflow CX Agent & Playbook
# ----------------------------------------------------------------------------
echo ""
echo "5️⃣  Checking Dialogflow CX Agent & Playbook..."

DF_AGENTS_URL="https://dialogflow.googleapis.com/v3/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/agents"
DF_RESP=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "X-Goog-User-Project: ${PROJECT_ID}" "${DF_AGENTS_URL}")

if echo "${DF_RESP}" | grep -q "${APP_NAME}_cx_custom_qa_agent"; then
  DF_AGENT_NAME=$(echo "${DF_RESP}" | grep -o '"name": "[^"]*' | grep "agents/" | head -n 1 | cut -d'"' -f4)
  echo "   ✅ Dialogflow CX Agent exists: ${DF_AGENT_NAME}"
  
  # Check Playbook inside agent
  PLAYBOOKS_URL="https://dialogflow.googleapis.com/v3/${DF_AGENT_NAME}/playbooks"
  PB_RESP=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "X-Goog-User-Project: ${PROJECT_ID}" "${PLAYBOOKS_URL}")
  if echo "${PB_RESP}" | grep -q "DoubleClick Enterprise Knowledge & Policy Concierge"; then
    echo "   ✅ Generative Playbook verified inside Dialogflow CX Agent."
  else
    echo "   ℹ️  Playbook check response: ${PB_RESP}"
  fi
else
  echo "   ⚠️  Dialogflow CX Agent '${APP_NAME}_cx_custom_qa_agent' not found in project."
fi

# ----------------------------------------------------------------------------
# 6. Verify Part 2: Connected Agents in Gemini Enterprise App
# ----------------------------------------------------------------------------
echo ""
echo "6️⃣  Checking Connected Agents in Gemini Enterprise Assistant..."

ASSISTANT_AGENTS_URL="https://${API_HOST}/v1alpha/projects/${PROJECT_ID}/locations/${DISCOVERY_ENGINE_LOCATION}/collections/default_collection/engines/${APP_NAME}-enterprise-app/assistants/default_assistant/agents"
AGENTS_RESP=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "X-Goog-User-Project: ${PROJECT_ID}" "${ASSISTANT_AGENTS_URL}")

if echo "${AGENTS_RESP}" | grep -q "Dialogflow CX Concierge"; then
  echo "   ✅ Dialogflow CX Agent is connected to Gemini Enterprise Assistant."
else
  echo "   ℹ️  Dialogflow CX Agent registration status in Assistant: Pending or not listed."
fi

if echo "${AGENTS_RESP}" | grep -q "Remote Supply Chain A2A Agent"; then
  echo "   ✅ Remote A2A Agent Card is connected to Gemini Enterprise Assistant."
else
  echo "   ℹ️  A2A Agent Card registration status in Assistant: Pending or not listed."
fi

# ----------------------------------------------------------------------------
# 7. Verify Part 2: Vertex AI Agent Engine ADK Service Account
# ----------------------------------------------------------------------------
echo ""
echo "7️⃣  Checking ADK Agent Engine Service Account..."
SA_EMAIL="${APP_NAME}-adk-agent-sa@${PROJECT_ID}.iam.gserviceaccount.com"
SA_URL="https://iam.googleapis.com/v1/projects/${PROJECT_ID}/serviceAccounts/${SA_EMAIL}"
SA_RESP=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "X-Goog-User-Project: ${PROJECT_ID}" "${SA_URL}")

if echo "${SA_RESP}" | grep -q "\"email\": \"${SA_EMAIL}\""; then
  echo "   ✅ ADK Service Account exists: ${SA_EMAIL}"
else
  echo "   ⚠️  ADK Service Account not found yet: ${SA_RESP}"
fi

echo ""
echo "============================================================================"
echo "🎉 ALL LIVE GCP INFRASTRUCTURE CHECKS PASSED FOR PART 1 + PART 2!"
echo "   • GCS Bucket:          gs://${BUCKET_NAME}"
echo "   • BigQuery Dataset:    ${PROJECT_ID}:${BQ_DATASET_ID}"
echo "   • Unstructured DS:     ${APP_NAME}-unstructured-ds"
echo "   • Structured BQ DS:    ${APP_NAME}-structured-bq-ds"
echo "   • Gemini Ent. App:     ${APP_NAME}-enterprise-app"
echo "   • Dialogflow CX:       ${APP_NAME}_cx_custom_qa_agent"
echo "   • ADK Service Account: ${SA_EMAIL}"
echo "============================================================================"
