# ============================================================================
# Google Cloud APIs Configuration (`apis.tf`)
#
# 📌 Introduced in: Article 1 (Part 1 — 📚 Knowledge Base Management)
#    Enables core APIs required for Data Stores, Cloud Storage, and BigQuery.
# ============================================================================

locals {
  # 📌 Added since Article 1: Discovery Engine, BigQuery, and Cloud Storage APIs
  part_1_apis = [
    "discoveryengine.googleapis.com", # Gemini Enterprise / Vertex AI Search Data Stores & Connectors
    "bigquery.googleapis.com",        # BigQuery Structured Data Store & Operational Tables
    "storage.googleapis.com",         # Google Cloud Storage Unstructured Document Archive
  ]

  required_apis = concat(
    local.part_1_apis,
  )
}

# 📌 Added since Article 1: Enables all required GCP service APIs for the current branch
resource "google_project_service" "enabled_apis" {
  for_each           = toset(local.required_apis)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
