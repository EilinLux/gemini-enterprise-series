# ============================================================================
# Vertex AI & Agent Engine Service Configuration (`vertex_ai_agent.tf`)
#
# 📌 Introduced in: Article 2 (Part 2 — 🗣️ Conversational Modeling)
#    Provisions the dedicated Service Account and least-privilege IAM bindings
#    required to deploy and run our code-first ADK Agent on Vertex AI Agent Engine,
#    giving it read access to our Part 1 Discovery Engine Data Stores and BigQuery tables.
# ============================================================================

# 📌 Added since Article 2: Dedicated Service Account for ADK on Vertex AI Agent Engine
resource "google_service_account" "adk_agent_engine_sa" {
  account_id   = "${var.app_name}-adk-agent-sa"
  display_name = "ADK Agent Engine Service Account (${var.company_name})"
  description  = "Since Article 2: Identity used by our ADK Python Agent deployed on Vertex AI Agent Engine"

  depends_on = [google_project_service.enabled_apis]
}

# 📌 Added since Article 2: Resource-scoped GCS IAM binding for the ADK Agent Service Account
#    Works even when the caller does not have project-wide resourcemanager.projects.setIamPolicy
resource "google_storage_bucket_iam_member" "adk_sa_gcs_viewer" {
  bucket = google_storage_bucket.enterprise_docs_and_staging.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.adk_agent_engine_sa.email}"
}

# 📌 Added since Article 2: Resource-scoped BigQuery Dataset IAM binding for the ADK Agent SA
resource "google_bigquery_dataset_iam_member" "adk_sa_bq_viewer" {
  dataset_id = google_bigquery_dataset.enterprise_kb.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.adk_agent_engine_sa.email}"
}

locals {
  # 📌 Added since Article 2: Optional project-wide runtime roles (requires Project IAM Admin)
  part_2_adk_sa_roles = [
    "roles/aiplatform.user",        # Invoke Gemini models & Vertex AI Agent Engine runtime
    "roles/discoveryengine.viewer", # Query Part 1 Gemini Enterprise Data Stores for Grounded RAG
    "roles/bigquery.dataViewer",    # Read Part 1 BigQuery tables (project_db & retail_sales)
    "roles/bigquery.jobUser",       # Execute BigQuery SQL & federated queries from ADK tools
    "roles/storage.objectViewer",   # Read staged ADK artifacts & unstructured docs in GCS
  ]
}

# 📌 Added since Article 2: Bind project-level IAM roles when caller has Project IAM Admin
resource "google_project_iam_member" "adk_agent_sa_bindings" {
  for_each = var.grant_project_iam_roles ? toset(local.part_2_adk_sa_roles) : toset([])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.adk_agent_engine_sa.email}"
}

