# ============================================================================
# Google Cloud APIs Configuration (`apis.tf`)
#
# 📌 Introduced in: Article 1 (Part 1 — 📚 Knowledge Base Management)
# 📌 Updated in:    Article 2 (Part 2 — 🗣️ Conversational Modeling)
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

  required_apis = concat(
    local.part_1_apis,
    local.part_2_apis,
  )
}

# 📌 Added since Article 1: Enables all required GCP service APIs for the current branch
resource "google_project_service" "enabled_apis" {
  for_each           = toset(local.required_apis)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
