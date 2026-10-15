# ============================================================================
# Google Cloud APIs Configuration (`apis.tf`)
#
# 📌 Introduced in: Article 1 (Part 1 — 📚 Knowledge Base Management)
# 📌 Updated in:    Article 2 (Part 2 — 🗣️ Conversational Modeling)
# 📌 Updated in:    Article 4 (Part 4 — 📈 Architecture & Monitoring)
# 📌 Updated in:    Article 5 (Part 5 — 🛡️ Integration & Security)
# ============================================================================

locals {
  # 📌 Added since Article 1: Discovery Engine, BigQuery, and Cloud Storage APIs
  part_1_apis = [
    "discoveryengine.googleapis.com", # Gemini Enterprise / Vertex AI Search Data Stores & Connectors
    "bigquery.googleapis.com",        # BigQuery Structured Data Store & Operational Tables
    "storage.googleapis.com",         # Google Cloud Storage Unstructured Document Archive
  ]

  # 📌 Added since Article 2: Dialogflow CX, CX Agent Studio (CES), Vertex AI Agent Engine, and IAM APIs
  part_2_apis = [
    "dialogflow.googleapis.com",      # Dialogflow CX Agents & Playbooks
    "ces.googleapis.com",             # Customer Engagement Suite — Next-Gen CX Agent Studio Apps & Agents
    "aiplatform.googleapis.com",      # Vertex AI Models & Vertex AI Agent Engine (ADK Runtime)
    "iam.googleapis.com",             # Service Account & IAM management for ADK Agents
  ]

  # 📌 Added since Article 4: Cloud Observability Suite (Cloud Trace, Cloud Logging & Cloud Monitoring)
  part_4_apis = [
    "cloudtrace.googleapis.com",      # OpenTelemetry distributed tracing for ADK Agent Engine & ReasoningEngine
    "logging.googleapis.com",         # Cloud Logging & Log Router Sink to BigQuery
    "monitoring.googleapis.com",      # Cloud Monitoring metrics & custom Agent Observability Dashboards
  ]

  # 📌 Added since Article 5: Security & Secret Manager API for OAuth 2.0 Action Credentials
  part_5_apis = [
    "secretmanager.googleapis.com",   # Secret Manager vault for Jira / Salesforce OAuth 2.0 Client Secrets
  ]

  required_apis = concat(
    local.part_1_apis,
    local.part_2_apis,
    local.part_4_apis,
    local.part_5_apis,
  )
}


# 📌 Added since Article 1: Enables all required GCP service APIs for the current branch
resource "google_project_service" "enabled_apis" {
  for_each           = toset(local.required_apis)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
